//
//  CourseListVO.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 6..
//  Copyright © 2017년 Hong. All rights reserved.
//

import Foundation

class PoiListVO: NSObject {
    
    var courseDNo: Int = 0
    var courseMNo: Int = 0
    var courseMNm: String = ""
    var beaconId: Int = 0
    var beaconNm: String = ""
    var beaconX: String = ""
    var beaconY: String = ""
    
    var oldtownContentsNo: Int = 0
    var contentsNo: Int = 0
    var contentsTitle: String = ""
    var contentsText: String = ""
    var contentsImg: String = ""
    var courseContentsYn: String = ""
    var visited: Bool = false
    var subImgList = [contentsSubImgVO]()
}
