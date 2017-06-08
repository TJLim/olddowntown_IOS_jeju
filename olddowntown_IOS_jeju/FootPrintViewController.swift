//
//  FootPrintViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 8..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit
import RealmSwift
import Tamra
import Alamofire

class FootPrintViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TamraManagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var beaconList:[String] = []
    var courseNmList:[String] = []
    
    var courseList:[FootPrintViewVO] = [FootPrintViewVO]()
    
    var imgData:[String]=[]
    let customCellIdentifier = "FootPrintCustomCell"
    var VisitBeaconAreaArr = [VisitBeaconArea]()

    var courseGroupList = [CourseGroupVO]()
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

        initTamraSet()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        imgData.append("raceFinish")
        imgData.append("raceMiddle")
        dataSet()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("FootPrintViewController : 비콘 검색 시작")
        
        for i in 0 ..< beaconGroupList.count {
            
            tamraManager.startMonitoring(forId: beaconGroupList[i])
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        print("FootPrintViewController : 비콘 검색 종료")
        
        tamraManager.stopMonitoring()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func initTamraSet() {
        
        /*비콘 검색 초기화*/
        Tamra.requestLocationAuthorization()
        
        tamraManager = TamraManager()
        tamraManager.delegate = self
        tamraManager.ready()
    }
    
    
    func dataSet() {
        
        let result = selectAllQuery()
        
        print("rrrrr : \(result)")
        
        for i in 0 ..< courseGroupList.count {
            
            let footPrintVO = FootPrintViewVO()
            
            footPrintVO.title = courseGroupList[i].courseMNm
            footPrintVO.courseMNo = courseGroupList[i].courseMNo
            footPrintVO.visitedCnt = 0
            
            courseList.append(footPrintVO)
        }
        
        for i in 0 ..< courseList.count {
            
             for VisitBeaconAreaData in result {
             
                if courseList[i].courseMNo == Int(VisitBeaconAreaData.courseMNo) {
                    courseList[i].visitedCnt += 1
                    courseList[i].title = VisitBeaconAreaData.courseMNm
                    
                    if courseList[i].visitedCnt != 0 {
                        
                        let date: String = String(VisitBeaconAreaData.regDt)

                        var returnStringArr = [String]();
                        
                        if date.contains("+") {
                            
                            returnStringArr = date.components(separatedBy: "+")
                            
                            courseList[i].date = returnStringArr[0]
                        }
                    }
                }
            }
        }
        
        for i in 0 ..< courseList.count {
            
            if courseList[i].visitedCnt == 0 {
                courseList[i].date = "-"
            }
        }
    }
    
    func tableView(_ tableview: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courseList.count
    }
    
    func tableView(_ tableview: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableview.dequeueReusableCellWithIdentifier(customCellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        var customCell = FootPrintCustomCell()
        
        customCell = tableview.dequeueReusableCell(withIdentifier: customCellIdentifier, for: indexPath) as! FootPrintCustomCell

        let row = indexPath.row
        
        customCell.tableCellLabel.text = courseList[row].title
        
        customCell.tableCellLabel.font = UIFont(name: (customCell.tableCellLabel.font?.fontName)!, size: 20)
        
        customCell.tableCellVisitCnt.text = "(\(courseList[row].visitedCnt) / \(courseGroupList[row].courseList.count))"
        customCell.tableCellVisitDate.text = "마지막 방문일 : \(String(describing: String(courseList[row].date)))"
        
        print("마지막 방문일 : \(String(describing: String(courseList[row].date)))")
        print("마지막 방문일 1 : \(courseList[row].date)")
        print("마지막 방문일 2 : \(String(describing: String(courseList[row].date)))")
        print()
        customCell.tableCellVisitDate.numberOfLines = 2
        customCell.tableCellVisitDate.adjustsFontSizeToFitWidth = true
        
        if courseList[row].visitedCnt == courseGroupList[row].courseList.count {
            customCell.tableCellImage.image = UIImage(named: imgData[0])
        } else {
            customCell.tableCellImage.image = UIImage(named: imgData[1])
        }
        return customCell
    }
    
   
    
    func tableView(_ tableview: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        tableCellIndex = row
        print(courseList[row].title)
        
        self.performSegue(withIdentifier: "FootPrintCourseDetail", sender: self)
//        self.dismissViewControllerAnimated(false, completion: nil)
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
                    self.mappingContentsNo = Int(contentsNo )
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
    
    func removeAllTask(){
        
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }

   
    func selectAllQuery() -> Results<VisitBeaconArea> {
        let realm = try! Realm()
        let allTask = realm.objects(VisitBeaconArea.self)
        
        return allTask
    }
    
    @IBAction func Back(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "FootPrintCourseDetail" {
            
            let segue = segue.destination as! FootPrintCourseViewController
            
            segue.courseList = self.courseGroupList[tableCellIndex].courseList
            segue.courseGroupList = self.courseGroupList
            segue.beaconGroupList = self.beaconGroupList
            
        } else if segue.identifier == "mappingContents" {
            
            let sendData = segue.destination as! MappingContentsViewController
            sendData.mappingContentsNo = self.mappingContentsNo
            sendData.mappingContentsTitle = self.mappingContentsTitle
            sendData.mappingFilePath = self.mappingFilePath
            
        }
    }
}
