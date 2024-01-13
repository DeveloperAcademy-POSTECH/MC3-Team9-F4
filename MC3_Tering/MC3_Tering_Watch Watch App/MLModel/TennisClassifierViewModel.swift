//
//  TennisClassifierViewModel.swift
//  MC3_Tering_Watch Watch App
//
//  Created by 김영빈 on 2023/07/26.
//

import CoreML
import CoreMotion

let MODEL_NAME = "TeringClassifier_totalData_window100"
let STATE_INPUT_SIZE = 400      // LSTM 모델 stateIn 인풋 사이즈
let WINDOW_SIZE = 100           // 슬라이딩 윈도우 사이즈
let PRE_BUFFER_SIZE = 30        // 스윙 감지 전 미리 채워놓을 버퍼 사이즈 (100->30 / 200->70) (WINDOW_SIZE에 따른 값)
let FREQUENCY = 50              // 데이터 빈도수
let THRESHOLD: Double = 0.8     // Perfect-Bad 기준 probability

// MARK: - 테니스 동작 분류 모델 관련 클래스
class TennisClassifierViewModel: ObservableObject {
    
    static let shared = TennisClassifierViewModel() // 싱글톤 인스턴스
    
    // 외부에서 인스턴스를 생성하지 못하도록 private init로 선언
    private init() {
        
        // 모델 불러오기
        guard let modelURL = Bundle.main.url(forResource: MODEL_NAME, withExtension: "mlmodelc") else {
            fatalError("Failed to locate the model file.")
        }
        guard let model = try? TeringClassifier_totalData_window100(contentsOf: modelURL) else {
            fatalError("Failed to create the model.")
        }
        mlModel = model
    }
    
    let motionManager = CMMotionManager()
    @Published var isDetecting = false              // device motion 데이터를 추적 중인지 여부
    @Published var isSwing = false                  // 스윙 중인지 체크
    
    @Published var forehandPerfectCount: Int = 0    // 포핸드 perfect 스윙 횟수
    @Published var forehandBadCount: Int = 0        // 포핸드 bad 스윙 횟수
    @Published var backhandPerfectCount: Int = 0    // 백핸드 perfect 스윙 횟수
    @Published var backhandBadCount: Int = 0        // 백핸드 bad 스윙 횟수
    @Published var totalCount: Int = 0              // 전체 스윙 횟수
    @Published var timestamp: Double = 0.0
    
    @Published var classLabel: String = "?"         // 동작 분류 결과
    @Published var resultLabel: String = "?"        // Perfect-Bad 결과
    @Published var confidence: String = "0.0"       // 분류 Confidence
    
    // 모델 인풋용 윈도우 버퍼
    var bufferAccX: [Double] = []
    var bufferAccY: [Double] = []
    var bufferAccZ: [Double] = []
    var bufferRotX: [Double] = []
    var bufferRotY: [Double] = []
    var bufferRotZ: [Double] = []
    
    var mlModel: TeringClassifier_totalData_window100 // 스윙 동작 분류 모델
    
    // MARK: - 감지 시작
    func startMotionTracking() {
        
        isDetecting = true
        
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion service is not available.")
            return
        }
        var startTime: TimeInterval = 0.0 // 시작 시간 저장 변수
        motionManager.deviceMotionUpdateInterval = 1.0 / Double(FREQUENCY) // 센서 데이터 빈도수 설정
        
        // Device Motion 데이터 업데이트 시작
        motionManager.startDeviceMotionUpdates(to: .main) { (deviceMotion, error) in
            
            guard let deviceMotionData = deviceMotion, error == nil else {
                print("Failed to get device motion data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if startTime == 0.0 {
                startTime = deviceMotionData.timestamp // 첫 번째 데이터의 타임스탬프 저장
            }
            let timestamp = deviceMotionData.timestamp - startTime // 시작 시간으로부터 경과한 시간 계산
            self.timestamp = timestamp
            
            if self.bufferRotZ.count < PRE_BUFFER_SIZE {
                self.appendDeviceMotionDataToBuffer(deviceMotionData) // 버퍼 채우기
                
            } else {
                if self.isSwing == false {
                    // 스윙 중이라는 것이 감지되면
                    if self.detectSwing(deviceMotionData) {
                        self.isSwing = true
                        
                    } else {
                        self.removeFirstDeviceMotionDataInBuffer() // 버퍼 내부 크기 유지
                    }
                    
                } else { // isSwing == true 일 때
                    // 버퍼 길이가 WINDOW_SIZE에 도달하면 인풋을 만들고 예측을 수행
                    if self.bufferRotZ.count >= WINDOW_SIZE {
                        let input = self.generateModelInput() // 인풋
                        guard let output = try? self.mlModel.prediction(input: input) else { // 예측 결과
                            print("Failed to predict.")
                            return
                        }
                        let label = output.label
                        let prob = output.labelProbability[output.label] ?? 0.0
                        self.updateToPredictResult(label: label, prob: prob) // 예측 결과에 따른 처리 수행
                        
                        // 예측 수행 뒤 버퍼 초기화
                        self.resetBuffers()
                        self.isSwing = false
                        
                    } else { // 버퍼 길이가 WINDOW_SIZE보다 작으면 계속 채워준다.
                        self.appendDeviceMotionDataToBuffer(deviceMotionData)
                        
                    }
                    
                }
                
            }
        }
    }
    
    // MARK: - 스윙 측정 중 감지 일시정지
    func pauseMotionTracking() {
        
        motionManager.stopDeviceMotionUpdates()
        resetBuffers() // 버퍼 초기화
    }
    
    // MARK: - 감지 종료
    func stopMotionTracking() {
        
        motionManager.stopDeviceMotionUpdates()
        resetBuffers() // 버퍼 초기화
        isDetecting = false
    }
    
    // MARK: 스윙 중 여부를 판단하는 메서드
    func detectSwing(_ deviceMotionData: CMDeviceMotion) -> Bool {
        
        let accX = deviceMotionData.userAcceleration.x
        let accY = deviceMotionData.userAcceleration.y
        let accZ = deviceMotionData.userAcceleration.z
        
        let sumOfAbsAcc = abs(accX) + abs(accY) + abs(accZ)
        let subOfAccXZ = accX + accZ

        if sumOfAbsAcc >= 6.0 && abs(accX) >= 3.0 && abs(accZ) >= 2.5 && abs(subOfAccXZ) <= 2.0 {
            return true
            
        } else {
            return false
            
        }
    }
    
    // MARK: - 모델 인풋 생성 메서드
    func generateModelInput() -> TeringClassifier_totalData_window100Input {
        
        // 인풋 생성
        let multiArrayAccX = try! MLMultiArray(bufferAccX)
        let multiArrayAccY = try! MLMultiArray(bufferAccY)
        let multiArrayAccZ = try! MLMultiArray(bufferAccZ)
        let multiArrayRotX = try! MLMultiArray(bufferRotX)
        let multiArrayRotY = try! MLMultiArray(bufferRotY)
        let multiArrayRotZ = try! MLMultiArray(bufferRotZ)
        let multiArrayStateIn = try! MLMultiArray(Array(repeating: 0.0, count: STATE_INPUT_SIZE))
        
        let input = TeringClassifier_totalData_window100Input(
            Acceleration_X: multiArrayAccX,
            Acceleration_Y: multiArrayAccY,
            Acceleration_Z: multiArrayAccZ,
            Rotation_Rate_X: multiArrayRotX,
            Rotation_Rate_Y: multiArrayRotY,
            Rotation_Rate_Z: multiArrayRotZ,
            stateIn: multiArrayStateIn
        )
        
        return input
    }
    
    // MARK: - 스윙 분류 결과 처리 메서드
    func updateToPredictResult(label: String, prob: Double) {
        
        classLabel = label
        confidence = String(prob)
        
        switch label {
        case "Forehand":
            if prob >= THRESHOLD {
                forehandPerfectCount += 1
                resultLabel = "PERFECT"
                
            } else {
                forehandBadCount += 1
                resultLabel = "BAD"
                
            }
        case "Backhand":
            if prob >= THRESHOLD {
                backhandPerfectCount += 1
                resultLabel = "PERFECT"
                
            } else {
                backhandBadCount += 1
                resultLabel = "BAD"
                
            }
        default:
            break
        }
        
        totalCount += 1
    }
    
    // MARK: - 버퍼 초기화 메서드
    func resetBuffers() {
        
        bufferAccX = []
        bufferAccY = []
        bufferAccZ = []
        bufferRotX = []
        bufferRotY = []
        bufferRotZ = []
    }
    
    // MARK: - 들어온 Device Motion 데이터를 버퍼에 추가해주는 메서드
    func appendDeviceMotionDataToBuffer(_ deviceMotionData: CMDeviceMotion) {
        
        bufferAccX.append(deviceMotionData.userAcceleration.x)
        bufferAccY.append(deviceMotionData.userAcceleration.y)
        bufferAccZ.append(deviceMotionData.userAcceleration.z)
        bufferRotX.append(deviceMotionData.rotationRate.x)
        bufferRotY.append(deviceMotionData.rotationRate.y)
        bufferRotZ.append(deviceMotionData.rotationRate.z)
    }
    
    // MARK: - 버퍼의 가장 앞에 있는 Deveice Motion 데이터를 제거해주는 메서드
    func removeFirstDeviceMotionDataInBuffer() {
        
        bufferAccX.removeFirst()
        bufferAccY.removeFirst()
        bufferAccZ.removeFirst()
        bufferRotX.removeFirst()
        bufferRotY.removeFirst()
        bufferRotZ.removeFirst()
    }
}
