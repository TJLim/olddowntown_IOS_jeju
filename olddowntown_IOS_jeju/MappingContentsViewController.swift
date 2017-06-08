//
//  MappingContentsViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 6..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit

/* 매핑된 비콘의 콘텐츠 보여주는 컨트롤러 */
class MappingContentsViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var NaviTItle: UINavigationItem!
    
    var mappingContentsNo: Int?
    var mappingContentsTitle: String?
    var mappingFilePath: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("filePath : \(String(describing: mappingFilePath))")
        
//        let req = NSURLRequest(URL: NSURL(string: ("http://192.168.17.12:8080/creativeEconomy/MobileMappingPage.do?contentsNo=\(mappingContentsNo!)"))!)

        let req = URLRequest(url: URL(string: mappingFilePath!)!)
        print("req :  \(req)")
        NaviTItle.title = mappingContentsTitle
        
        webView.loadRequest(req)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func Back(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
