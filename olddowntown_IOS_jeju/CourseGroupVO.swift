//
//  CourseGroupVO.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 6..
//  Copyright © 2017년 Hong. All rights reserved.
//

import Foundation

class CourseGroupVO: NSObject {
    
    var courseGroupNo : Int = 0
    var courseMNo : Int = 0
    var courseMNm : String = ""
    var coursePoiCount: Int = 0
    var courseMText: String = ""
    var courseMImg: String = ""
    
    var courseList = [PoiListVO]()
}

