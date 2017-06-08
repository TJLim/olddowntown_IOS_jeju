//
//  BeaconMappingSchedulerVO.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 24..
//  Copyright © 2017년 Hong. All rights reserved.
//

import Foundation
import RealmSwift

class BeaconMappingSchedulerVO: Object {
    
    dynamic var title: String = ""
    dynamic var timestamp: Int = 0
    dynamic var beaconId: Int = 0
}
