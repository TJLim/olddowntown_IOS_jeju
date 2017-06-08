//
//  IntroductionDetailViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 15..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit
import Tamra
import Alamofire
import RealmSwift


class IntroductionDetailViewController: UIViewController, TamraManagerDelegate {

    @IBOutlet weak var navigationLabel: UINavigationItem!
    var intro: IntroductionVO?
    var m_Scrollview = UIScrollView()   // 주요 코스 메인 스크롤뷰
    
    let screenWidth = UIScreen.main.bounds.size.width   // 뷰 전체 폭 길이
    let screenHeight = UIScreen.main.bounds.size.height // 뷰 전체 높이 길이
    
    var courseGroupList = [CourseGroupVO]()
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
        
        navigationLabel.title = intro?.title
        makeUIData()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("viewDidAppear : 비콘 검색 시작")
        
        for i in 0 ..< beaconGroupList.count {
            tamraManager.startMonitoring(forId: beaconGroupList[i])
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("IntroductionViewController : 비콘 검색 종료")
        tamraManager.stopMonitoring()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        print("IntroductionViewController : 비콘 검색 종료")
//        tamraManager.stopMonitoring()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func Back(_ sender: AnyObject) {
        
        self.dismiss(animated: false, completion: nil)
    }
    
    func initTamraSet() {
        
        /*비콘 검색 초기화*/
        Tamra.requestLocationAuthorization()
        
        tamraManager = TamraManager()
        tamraManager.delegate = self
        tamraManager.ready()
    }
    
    func makeUIData() {
        
        m_Scrollview.frame = CGRect(x:0, y: 44, width: screenWidth, height: screenHeight - 44)

        var addUIHeight: CGFloat = 0
        let ImageView = UIImageView()
        let labelCourse = UILabel()
        let labelCourseDetail = UILabel()
        let labelDescription = UILabel()
        let labelDescriptionDetail = UILabel()
        
        addUIHeight = 20
        
        if intro?.image != "" {
            
            ImageView.frame = CGRect(x: 30, y: addUIHeight, width: screenWidth - 60, height: screenHeight / 4 )
            
            var letImage = UIImage()
        
            let url: NSString = "http://221.162.53.24:8080\(intro!.image)" as NSString
//            let url: NSString = "http://www.jeju-showcase.com\(intro!.image)" as NSString
            
            
            let urlStr : NSString = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)! as NSString
            let searchURL: URL = URL(string: urlStr as String)!
        
            let data = try? Data(contentsOf: searchURL)
        
            // It is the best way to manage nil issue.
            if data!.count > 0 {
                letImage = UIImage(data:data!)!
            } else {
                // In this when data is nil or empty then we can assign a placeholder image
                letImage = UIImage(named: "placeholder.png")!
            }

            ImageView.image = letImage
//            ImageView.contentMode = UIViewContentMode.ScaleAspectFit
            m_Scrollview.addSubview(ImageView)
            addUIHeight = 80 + screenHeight / 5
            
            addUIHeight += 10
        }

        labelDescriptionDetail.text = intro?.text
        labelDescriptionDetail.numberOfLines = 0
        
        let cellHeight = calculateContentHeight(labelDescriptionDetail)
        labelDescriptionDetail.frame = CGRect(x: 10, y: addUIHeight, width: screenWidth - 20, height: cellHeight)
        
        addUIHeight += cellHeight
        addUIHeight += 35
        
        labelCourse.frame = CGRect(x: 5, y: addUIHeight, width: screenWidth - 5, height: 20)
        labelCourse.text = "\(intro!.title) 내 볼거리"
        labelCourse.textColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        labelCourse.font = UIFont(name: (labelCourse.font?.fontName)!, size: 22)
        
        addUIHeight += 35
        labelCourseDetail.text = intro?.course
        labelCourseDetail.numberOfLines = 0
        
        var cellHeight2 = calculateContentHeight(labelCourseDetail)
        cellHeight2 += 15
        labelCourseDetail.frame = CGRect(x: 10, y: addUIHeight, width: screenWidth - 20, height: cellHeight2)

        print("cellHeight : \(cellHeight) / cellHeight2 : \(cellHeight2)")
        
        addUIHeight += cellHeight2
        
        m_Scrollview.addSubview(labelCourse)
        m_Scrollview.addSubview(labelCourseDetail)
        m_Scrollview.addSubview(labelDescription)
        m_Scrollview.addSubview(labelDescriptionDetail)
        m_Scrollview.contentSize = CGSize(width: screenWidth, height: addUIHeight)
        
        self.view.insertSubview(m_Scrollview, aboveSubview: self.view)
//        self.view.addSubview(m_Scrollview)
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
    
    func calculateContentHeight(_ setLable: UILabel) -> CGFloat {
        
        let widthSizeminus: CGFloat = 30
        let maxlabelSize: CGSize = CGSize(width: self.view.frame.size.width - widthSizeminus, height: CGFloat(9999))
        
        let options:NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
        let contentNSString = setLable.text! as NSString
        let expectedLabelSize = contentNSString.boundingRect(with: maxlabelSize, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17.0)], context: nil)
        
        return expectedLabelSize.size.height
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "mappingContents" {
            
            let sendData = segue.destination as! MappingContentsViewController
            sendData.mappingContentsNo = self.mappingContentsNo
            sendData.mappingContentsTitle = self.mappingContentsTitle
            sendData.mappingFilePath = self.mappingFilePath
            
        }
    }
}
