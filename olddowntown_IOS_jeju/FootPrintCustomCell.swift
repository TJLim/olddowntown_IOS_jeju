//
//  CustomCell.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 13..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit

class FootPrintCustomCell: UITableViewCell {

//    @IBOutlet var tableCellLabel: UILabel!
//    @IBOutlet var tableCellImage: UIImageView!
//    @IBOutlet weak var tableCellVisitCnt: UILabel!
//    @IBOutlet weak var tableCellVisitDate: UILabel!
    var tableCellLabel = UILabel()
    var tableCellImage = UIImageView()
    var tableCellVisitCnt = UILabel()
    var tableCellVisitDate = UILabel()
    
    var screenWidth = UIScreen.main.bounds.size.width   // 뷰 전체 가로 길이
    var screenHeight = UIScreen.main.bounds.size.height // 뷰 전체 세로 길이
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        tableCellLabel.frame = CGRect(x: 5, y: 0, width: screenWidth / 4 * 3, height: (screenHeight - 44) / 13)
        tableCellVisitCnt.frame = CGRect(x: screenWidth / 4 * 3 + 15, y: 0, width: screenWidth / 4, height: (screenHeight - 44) / 13)
        tableCellImage.frame = CGRect(x: 5, y: (screenHeight - 44) / 13, width: screenWidth / 2, height: (screenHeight - 44) / 13)
        tableCellVisitDate.frame = CGRect(x: screenWidth / 2 + 15, y: (screenHeight - 44) / 13, width: screenWidth / 2, height: (screenHeight - 44) / 13)
        
        self.addSubview(tableCellLabel)
        self.addSubview(tableCellVisitCnt)
        self.addSubview(tableCellImage)
        self.addSubview(tableCellVisitDate)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
