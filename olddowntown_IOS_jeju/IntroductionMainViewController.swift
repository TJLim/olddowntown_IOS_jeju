//
//  IntroductionMainViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 20..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit
import Tamra
import Alamofire
import RealmSwift

class IntroductionMainViewController: UIViewController, TamraManagerDelegate {

//    @IBOutlet weak var infoLabel: UILabel!
    
    var courseGroupList = [CourseGroupVO]()
    let screenWidth = UIScreen.main.bounds.size.width   // 뷰 전체 폭 길이
    let screenHeight = UIScreen.main.bounds.size.height // 뷰 전체 높이 길이
    
    var beaconGroupList = [Int]()   // 비콘 그룹 리스트
    var tamraManager: TamraManager!
    
    var visited: [Int: Visit] = [:]
    
    var mappingContentsNo: Int?
    var mappingContentsTitle: String?
    var mappingFilePath: String?
    
    var common: CommonController = CommonController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initTamraSet()
        dataInit()
   
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        print("IntroductionMainViewController : 비콘 검색 시작")

        for i in 0 ..< beaconGroupList.count {
            tamraManager.startMonitoring(forId: beaconGroupList[i])
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("IntroductionMainViewController : 비콘 검색 종료")
        tamraManager.stopMonitoring()
    }
    
//    override func viewDidDisappear(animated: Bool) {
//        super.viewDidDisappear(animated)
//        
//        print("IntroductionMainViewController : 비콘 검색 종료")
//        tamraManager.stopMonitoring()
//    }


    func initTamraSet() {
        
        /*비콘 검색 초기화*/
        Tamra.requestLocationAuthorization()
        
        tamraManager = TamraManager()
        tamraManager.delegate = self
        tamraManager.ready()
    }
    
    func dataInit() {
        
        makeUI()
        
    }
    
    func makeUI() {
        
        let mScroll = UIScrollView()
        let ImageView = UIImageView()
        let mainInfoLabel = UILabel()
        let courseInfoListGoBtn = UILabel()
        
//        let mScrollImg = UIImageView()
        
        let UIImageBackground = UIImageView()
        UIImageBackground.image = UIImage(named: "intro2_max.jpg")
        UIImageBackground.frame = CGRect(x: 0, y: 94, width: screenWidth, height: screenHeight - 94)
        //UIImageBackground.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.9)
        UIImageBackground.alpha = 0.2
        
        mScroll.frame = CGRect(x: 15, y: 100, width: screenWidth - 30, height: screenHeight - 200)

        ImageView.image = UIImage(named: "mainImg.JPG")!
        
        ImageView.frame = CGRect(x: 5, y: 0, width: screenWidth - 10, height: screenHeight / 5 + 20)
        
        
        mainInfoLabel.font = UIFont(name: (mainInfoLabel.font?.fontName)!, size: 16)
        mainInfoLabel.numberOfLines = 0
        mainInfoLabel.text = "제주 성안, 성내로 일컬어지는 현 제주시 원도심 일대는 과거 탐라, 조선시대를 거쳐 20세기 후반까지 제주의 정치·경제·사회·문화의 중심지였다. 1980년대 새로운 택지개발로 인해 원도심의 기능이 도심 외곽으로 분산되기 시작하면서 원도심은 제주의 중심지 기능을 잃게 되었다. 제주시 원도심은 제주 역사문화자원의 보고로 다양한 시대의 기억과 경험을 공유하고 있다. 21세기 도시재생이라는 시대적 화두 아래 원도심은 재생사업에 없어서는 안될 제주만의 도심 정체성으로 재평가 받고 있다.\n\n제주 성안, 성내로 일컬어지는 현 제주시 원도심 일대는 과거 탐라, 조선시대를 거쳐 20세기 후반까지 제주의 정치·경제·사회·문화의 중심지로 기능했다. 탐라시대에는 탐라건국 신화인 고(髙)·양(良)·부(夫) 삼성(三姓)이 활을 쏘아 각기 화살이 꽂힌 자리를 중심으로 제일도(第一徒), 제이도(第二徒), 제삼도(第三徒)로 나누어 통치하였다는 신화가 전해져오고 있다. 또한 고려시대에는 탐라총관부(현, 북초등학교 북쪽 추정)가 설치되어 원제국의 직할지로 기능했으며, 조선시대에는 전라도 제주목으로 편입되어 목관아를 중심으로 한 지방행정이 이뤄졌다. 이렇듯 원도심은 제주 역사의 산실이자 제주 행정의 중심지였던 것이다.\n이후, 해방과 한국 전쟁을 거치며 제주시는 급속한 도시화를 경험하게 된다. 이때부터 옛 목관아지 일대는 도청, 경찰서, 법원 등 각종 관공서들이 밀집한 근대 도시로서의 모습을 갖추게 되었다. 하지만 오랜 기간 제주의 중심이었던 원도심 일대는 1980년대 새로운 택지개발로 인한 도심기능의 외곽이전에 따라 점진적인 쇠퇴를 경험하게 된다.\n그럼에도 불구하고 오늘날의 제주 원도심은 다양한 역사와 문화가 공존하는 제주만의 독톡한 도시문화와 도시경관을 탄생시켰다. 도시재생이 화두인 21세기, 제주 원도심에 대한 도민의 기억과 삶의 자취는 오늘날 도시재생 사업에 없어서는 안 될 귀중한 역사문화자원으로 재조명 받고 있다."
        
        let mainInfoLabelHeight = calculateContentHeight(mainInfoLabel)
        
        mainInfoLabel.frame = CGRect(x: 0, y: screenHeight / 4, width: screenWidth - 30, height: mainInfoLabelHeight)

//        mScrollImg.contentMode = UIViewContentMode.ScaleAspectFit
//        mScrollImg.frame = CGRectMake(0, 0, screenWidth - 30, screenHeight - 200)
        
        courseInfoListGoBtn.frame = CGRect(x: 15, y: screenHeight - 70, width: 120, height: 50)
        courseInfoListGoBtn.backgroundColor = UIColor(red: 38/255, green: 141/255, blue: 198/255, alpha: 1)
        courseInfoListGoBtn.text = "코스 소개"
        courseInfoListGoBtn.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        courseInfoListGoBtn.font = UIFont(name: (courseInfoListGoBtn.font?.fontName)!, size: 22)
        courseInfoListGoBtn.textAlignment = .center
        
        let target = UITapGestureRecognizer(target: self, action: #selector(IntroductionMainViewController.courseInfoListGO(_:)))
        target.numberOfTapsRequired = 1

        courseInfoListGoBtn.isUserInteractionEnabled = true
        courseInfoListGoBtn.addGestureRecognizer(target)
        
        mScroll.contentSize = CGSize(width: screenWidth - 30, height: mainInfoLabelHeight + (screenHeight / 4))
        mScroll.addSubview(ImageView)
        mScroll.addSubview(mainInfoLabel)
//        mScroll.addSubview(mScrollImg)
        
        self.view.addSubview(UIImageBackground)
        self.view.addSubview(mScroll)
        self.view.addSubview(courseInfoListGoBtn)
        
    }
    
    func courseInfoListGO(_ recognizer: UITapGestureRecognizer) {
        
        self.performSegue(withIdentifier: "CourseListSegue", sender: self)
    }
    
    func calculateContentHeight(_ setLable: UILabel) -> CGFloat {
        
        let widthSizeminus: CGFloat = 15
        let maxlabelSize: CGSize = CGSize(width: self.view.frame.size.width - widthSizeminus, height: CGFloat(9999))
        
        let options:NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let contentNSString = setLable.text! as NSString
        let expectedLabelSize = contentNSString.boundingRect(with: maxlabelSize, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17.0)], context: nil)
        
        return expectedLabelSize.size.height
    }
    
    
    func tamraManager(didRangeSpots spots: TamraNearbySpots) {
        let filtered = spots.filter {
            spot in
            return spot.proximity == .immediate || spot.proximity == .near
        }
        
        for spot in filtered {
            if let visit = visited[spot.id] {
                visited[spot.id] = visit.update()
            } else {
                visited[spot.id] = Visit(desc: spot.desc, entry: NSDate() as Date)
                let message = "\(spot.desc) 에 접근했습니다."
                
                print(message)
                
                isExistsMappingContentsId(spot.id, spotDesc: spot.desc)
            }
        }
    }
    
    
    /* Alamofire 를 이용하여 웹페이지 url을 호출하고 그에 맞는 결과값을 얻어 내오는 함수.
     
     감지한 비콘의 매핑 컨텐츠가 존재하는 경우 alert창을 띄움
     감지한 비콘의 매핑 컨텐츠가 존재하지 않는 경우 반응 없음
     */
    func isExistsMappingContentsId(_ spotId: Int, spotDesc: String) {
        
        print("CourseTourViewController : 매핑 컨텐츠 검색 시작")
        Alamofire.request(common.mappingURL, method: .get, parameters: ["beaconId": spotId, "userKey": "nndoonw"]).responseJSON{
        //Alamofire.request(.GET, common.mappingURL, parameters: ["beaconId": spotId, "userKey": "nndoonw"]).responseJSON{
            
            response in switch response.result {
                
            case .success(let JSON):
                
                let response = JSON as! NSDictionary
                
                // 응답 Json 의 Key인 "contentsNo" 로 Value를 얻음
                let contentsNo: String = response.object(forKey: "contentsNo")! as! String
                let contentsTitle = response.object(forKey: "contentsTitle")
                let filePath = response.object(forKey: "filePath")
                
                print("Mapping Contents No : \(contentsNo)")
                
                // 리턴 받은 Json 의 Value가 FALSE가 아닌 경우 메시지창 띄움
                if !contentsNo.isEqual("FALSE") {
                    
                    self.LocalDbInsert(spotId)
                    self.mappingContentsNo = Int(contentsNo)
                    self.mappingContentsTitle = contentsTitle as? String
                    self.mappingFilePath = filePath as? String
                    
                    self.makeAlertMessage(spotDesc)
                }
                
            case .failure(let error):
                print("Request failed with error: \(error)")
            }
        }
        
        print("Main_ViewController : 매핑 컨텐츠 검색 종료")
    }
    
    
    /* 매핑된 컨텐츠가 있을 경우 alert창을 띄워 매핑 컨텐츠를 보여줄지 말지 선택하는 함수*/
    func makeAlertMessage(_ name: String) {
        
        let alert = UIAlertController(title: "비콘신호감지", message: "\(name)에서 비콘 신호를 감지하였습니다.\n해당 내용을 확인 하시겠 습니까?", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "확인", style: .default) {
            (parameter) -> Void in
            
            self.performSegue(withIdentifier: "mappingContents", sender: self)
        }
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(cancel)
        alert.addAction(ok)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func LocalDbInsert(_ beaconId: Int) {
        
        print("CourseTourViewController : 로컬 디비에 감지한 비콘Id \(beaconId) 저장 시도")
        
        let result = makeQuery("beaconId BEGINSWITH '\(beaconId)'")
        
        
        if result.count == 0 {
            
            for i in 0 ..< courseGroupList.count {
                
                for j in 0 ..< courseGroupList[i].courseList.count {
                    
                    if courseGroupList[i].courseList[j].beaconId == beaconId {
                        
                        makeTask(beaconId, courseMNo: courseGroupList[i].courseList[j].courseMNo, courseMNm: courseGroupList[i].courseList[j].courseMNm)
                    }
                }
            }
            
            print("CourseTourViewController : 비콘Id \(beaconId) 저장 완료")
            
        } else {
            
            for VisitBeaconArea in result {
                
                print(VisitBeaconArea.beaconId)
                print(VisitBeaconArea.regDt)
                print("CourseTourViewController : 비콘Id \(beaconId)은 이미 저장되어 있음")

            }
            
            removeTask(result)
            
            for i in 0 ..< courseGroupList.count {
                
                for j in 0 ..< courseGroupList[i].courseList.count {
                    
                    if courseGroupList[i].courseList[j].beaconId == beaconId {
                        
                        makeTask(beaconId, courseMNo: courseGroupList[i].courseList[j].courseMNo, courseMNm: courseGroupList[i].courseList[j].courseMNm)
                    }
                }
            }
        }
    }
    
    
    func makeTask(_ beaconId: Int, courseMNo: Int, courseMNm: String){
        
        let task = VisitBeaconArea()
        
        task.beaconId = String(beaconId)
        task.courseMNo = String(courseMNo)
        task.courseMNm = courseMNm
        task.regDt = String(describing: Date())
        let realm = try! Realm()
        
        try! realm.write {
            realm.add(task)
        }
    }
    
    func removeTask(_ task: Results<VisitBeaconArea>){
        let realm = try! Realm()
        try! realm.write {
            realm.delete(task)
        }
    }
    func makeQuery(_ query:String) -> Results<VisitBeaconArea>{
        
        let realm = try! Realm()
        let allTask = realm.objects(VisitBeaconArea.self)
        let queryResult = allTask.filter(query)
        return queryResult
    }
    
    
    @IBAction func Back(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "mappingContents" {
            
            let sendData = segue.destination as! MappingContentsViewController
            sendData.mappingContentsNo = self.mappingContentsNo
            sendData.mappingContentsTitle = self.mappingContentsTitle
            sendData.mappingFilePath = self.mappingFilePath
            
        } else if segue.identifier == "CourseListSegue" {
            
            let segue = segue.destination as! IntroductionViewController
            
            segue.courseGroupList = self.courseGroupList
            segue.beaconGroupList = self.beaconGroupList
            
        }
    }
}
