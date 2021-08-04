//
//  ViewController.swift
//  MJThirdManager
//
//  Created by chenminjie92@126.com on 03/16/2021.
//  Copyright (c) 2021 chenminjie92@126.com. All rights reserved.
//

import UIKit
import MJThirdManager

class ViewController: UIViewController {

    deinit {
        MJPayManager.shared.remove(self)
        MJShareManager.shared.remove(self)
        MJLoginManager.shared.remove(self)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        MJPayManager.shared.add(self)
        MJShareManager.shared.add(self)
        MJLoginManager.shared.add(self)
        
        let button: UIButton = UIButton.init(frame: CGRect.init(x: 100, y: 100, width: 100, height: 100))
        button.backgroundColor = UIColor.red
        button.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        view.addSubview(button)
        
        let shareButton: UIButton = UIButton.init(frame: CGRect.init(x: 100, y: 300, width: 100, height: 100))
        shareButton.backgroundColor = UIColor.green
        shareButton.addTarget(self, action: #selector(shareButtonClick), for: .touchUpInside)
        view.addSubview(shareButton)
        
        let loginButton: UIButton = UIButton.init(frame: CGRect.init(x: 100, y: 500, width: 100, height: 100))
        loginButton.backgroundColor = UIColor.yellow
        loginButton.addTarget(self, action: #selector(loginButtonClick), for: .touchUpInside)
        view.addSubview(loginButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController {
    
    @objc func buttonClick() {
        MJPayManager.shared.pay(for: .zhifubao(orderCode: "", orderNo: nil))
    }
    
    @objc func shareButtonClick() {
        MJShareManager.shared.share(platform: .weixin(scene: .session, type: .link(urlString: "https://www.baidu.com", title: "分享标题", description: "分享内容", thumbData:nil)))
    }
    
    @objc func loginButtonClick() {
        MJLoginManager.shared.login(platform: .apple)
    }
}

extension ViewController: MJPayManagerProtocol {
    
    func onPayComplete(resultStatus: MJPayManager.ResultStatus, platform: MJPayManager.Platform?) {
        print(resultStatus)
        print(platform)
    }
    
    
}

extension ViewController: MJLoginManagerProtocol {
    
    func onLoginComplete(_ resultStatus: MJLoginManager.ResultStatus, platform: MJLoginManager.Platform?) {
        print(resultStatus)
    }
    
    
}
extension ViewController: MJShareManagerProtocol {
    
    func onShareComplete(_ resultStatus: MJShareManager.ResultStatus) {
        print(resultStatus)
    }
}

