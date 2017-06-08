//
//  IntroductionViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 14..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit
import Tamra
import Alamofire
import RealmSwift


class IntroductionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TamraManagerDelegate {

    var courseNmList:[String] = []
    var courseGroupList = [CourseGroupVO]()
    @IBOutlet weak var tableView: UITableView!
    let customCellIdentifier = "IntroductionCustomCell"
    
    var introList :[IntroductionVO] = [IntroductionVO]()
    var tableCellIndex: Int = -1

    var beaconGroupList = [Int]()   // 비콘 그룹 리스트
    var tamraManager: TamraManager!
    
    var visited: [Int: Visit] = [:]
    
    var mappingContentsNo: Int?
    var mappingContentsTitle: String?
    var mappingFilePath: String?
    var common: CommonController = CommonController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        initTamraSet()
        
        setData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("IntroductionViewController : 비콘 검색 시작")
        for i in 0 ..< beaconGroupList.count {
            tamraManager.startMonitoring(forId: beaconGroupList[i])
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("IntroductionViewController : 비콘 검색 종료")
        tamraManager.stopMonitoring()
    }
    
//    override func viewDidDisappear(animated: Bool) {
//        super.viewDidDisappear(animated)
//        
//        print("IntroductionViewController : 비콘 검색 종료")
//        tamraManager.stopMonitoring()
//    }
    
        
    func initTamraSet() {
        
        /*비콘 검색 초기화*/
        Tamra.requestLocationAuthorization()
        
        tamraManager = TamraManager()
        tamraManager.delegate = self
        tamraManager.ready()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func setData() {
        
        for i in 0 ..< courseGroupList.count {
            
            courseNmList.append(courseGroupList[i].courseMNm)
            
            let introVO = IntroductionVO()
            
            introVO.title = courseNmList[i]
            introVO.text = courseGroupList[i].courseMText
            introVO.image = courseGroupList[i].courseMImg
            introVO.course = ""
            
            for j in 0 ..< courseGroupList[i].courseList.count {
                
                if j == 0 {
                    introVO.course = courseGroupList[i].courseList[j].contentsTitle
                } else if j != 0 && j != courseGroupList[i].courseList.count - 1 {
                    introVO.course += ", \(courseGroupList[i].courseList[j].contentsTitle)"
                }
            }
            
            introList.append(introVO)
        }
    }
    

    @IBAction func Back(_ sender: AnyObject) {
        
        self.dismiss(animated: false, completion: nil)
    }
    
    func tableView(_ tableview: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.courseNmList.count
    }
    
    
    func tableView(_ tableview: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var customCell = IntroductionCustomCell()
        
        customCell = tableview.dequeueReusableCell(withIdentifier: customCellIdentifier, for: indexPath) as! IntroductionCustomCell

        let row = indexPath.row
        
        customCell.tableCellLabel.text = courseNmList[row]
        
        return customCell
    }
    
    
    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableview.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        
        print(courseNmList[row])
        tableCellIndex = row

        self.performSegue(withIdentifier: "IntroductionDetail", sender: self)
    }
    
    
//    func tamraManager(didReadyState state: TamraManagerState) {
//        if state == .Ignored || state == .Loaded {
//            
//            // ready
//            print("tamraManager : 비콘 검색 시작")
//            for i in 0 ..< beaconGroupList.count {
//                tamraManager.startMonitoring(forId: beaconGroupList[i])
//            }
//            
//        } else if state == .LoadingFailed {
//            // not ready
//        }
//    }
    

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
            
            //            makeTask(beaconId)
            print("CourseTourViewController : 비콘Id \(beaconId) 저장 완료")
        } else {
            
            for VisitBeaconArea in result {
                
                print(VisitBeaconArea.beaconId)
                print(VisitBeaconArea.regDt)
                print("CourseTourViewController : 비콘Id \(beaconId)은 이미 저장되어 있음")
                
                
                //                updateTask(Int(VisitBeaconArea.beaconId)!)
                //                VisitBeaconArea.regDt = NSDate()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "mappingContents" {
            
            let sendData = segue.destination as! MappingContentsViewController
            sendData.mappingContentsNo = self.mappingContentsNo
            sendData.mappingContentsTitle = self.mappingContentsTitle
            sendData.mappingFilePath = self.mappingFilePath
            
        } else if segue.identifier == "IntroductionDetail" {
            
            let segue = segue.destination as! IntroductionDetailViewController
            
            segue.courseGroupList = self.courseGroupList
            segue.intro = self.introList[tableCellIndex]
            segue.beaconGroupList = self.beaconGroupList
        }
    }
    
    
}
