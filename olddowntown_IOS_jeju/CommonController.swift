//
//  CommonController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 4. 14..
//  Copyright © 2017년 Hong. All rights reserved.
//

import Foundation


class CommonController {
    
    static var Host: String = "http://221.162.53.24:8080"  // 창경 서버
    
//    static var Host: String = "http://218.157.145.72:10"   // 민석 옆 노트북
//    var Host: String = "http://192.168.17.12:8080"  // 치홍 레노버
    
    
    var getCourseDataURL: String = "\(Host)/creativeEconomy/OldDownTownCourseListData.do"

    /* 비콘ID로 콘텐츠 매핑정보 얻어오는 URL */
    var mappingURL: String = "\(Host)/creativeEconomy/UserMappingInfoData.do"    // 창경 서버    
    
    var getRelationCourse: String = "\(Host)/creativeEconomy/OldTownRelationCourseData.do"
}
