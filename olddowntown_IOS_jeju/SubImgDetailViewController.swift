//
//  SubImgDetailViewController.swift
//  olddowntownbeaconapp.ios.legacy
//
//  Created by 안치홍 on 2017. 3. 28..
//  Copyright © 2017년 Hong. All rights reserved.
//

import UIKit

/* 서브이미지 확대 컨트롤러 */
class SubImgDetailViewController: UIViewController, UIScrollViewDelegate {

    var subImage: String = ""
    var subImageText: String = ""
    let screenWidth = UIScreen.main.bounds.size.width   // 뷰 전체 폭 길이
    let screenHeight = UIScreen.main.bounds.size.height // 뷰 전체 높이 길이
    
    @IBOutlet weak var naviBar: UINavigationBar!
    let ImageScrollView = UIScrollView()
    let ImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        makeUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func Back(_ sender: AnyObject) {
        self.dismiss(animated: false, completion: nil)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return ImageView
    }

    
    func makeUI() {

        ImageScrollView.frame = CGRect(x: 0, y: 44, width: screenWidth, height: screenHeight-92)
        ImageScrollView.minimumZoomScale = 1.0
        ImageScrollView.maximumZoomScale = 2.0
        ImageScrollView.delegate = self
        
        let ImageLabel = UILabel()
        var letImage = UIImage()
        let url: NSString = "http://221.162.53.24:8080\(subImage)" as NSString
        
//        let url: NSString = "http://www.jeju-showcase.com\(subImage)" as NSString
        
        
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
        
        ImageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight-92)
        ImageView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        ImageView.contentMode = UIViewContentMode.scaleAspectFit
        ImageView.clipsToBounds = false
        
        ImageScrollView.addSubview(ImageView)
        ImageScrollView.contentSize = ImageView.frame.size

        
        ImageLabel.text = subImageText
        ImageLabel.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        ImageLabel.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        ImageLabel.frame = CGRect(x: 0, y: screenHeight - 48, width: screenWidth, height: 48)
        ImageLabel.numberOfLines = 0
    
        self.view.addSubview(ImageScrollView)
        self.view.addSubview(ImageLabel)
        self.view.insertSubview(naviBar, aboveSubview: ImageScrollView)
    }
}
