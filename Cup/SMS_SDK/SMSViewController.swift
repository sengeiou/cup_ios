
//
//  SMSViewController.swift
//  Cup
//
//  Created by king on 15/11/9.
//  Copyright © 2015年 king. All rights reserved.
//

import UIKit
import RxSwift
import Moya
import SwiftyJSON
class SMSViewController: UIViewController {
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var verificationTextField: UITextField!
    @IBOutlet weak var verificationButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    let disposeBag = DisposeBag()
    var timer: NSTimer?
    var count = 90
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.verificationButton.rx_tap.subscribeNext { [unowned self] in
            if let phone = self.phoneTextField.text where phone.checkMobileNumble() {
                SMSSDK.getVerificationCodeByMethod(SMSGetCodeMethodSMS, phoneNumber: phone, zone: "86", customIdentifier: nil, result: {
                    if let error = $0 {
                        let alert = UIAlertController(title: nil, message: "\(error.userInfo["getVerificationCode"])", preferredStyle: .Alert)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }else{
                        self.loginButton.userInteractionEnabled = true
                        self.timer =  NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "setVerificationButtonText", userInfo: nil, repeats: true)
                        self.verificationButton.userInteractionEnabled = false
                        self.count = 90
                    }
                })
            }else{
                self.noticeError("手机号码错误，请重新输入", autoClear: true)
            }
            
            }.addDisposableTo(disposeBag)
        self.loginButton.rx_tap.subscribeNext { [weak self] in
            SMSSDK.commitVerificationCode(self!.verificationTextField.text, phoneNumber: self!.phoneTextField.text, zone: "86", result: {
                if let error = $0 {
                    self?.noticeError("\(error.userInfo["commitVerificationCode"])", autoClear: true)
                }else{
                    self!.phonelogin()
                }
            })
            
            }.addDisposableTo(disposeBag)
    }
    func setVerificationButtonText(){
        if count == 0 {
            self.verificationButton.userInteractionEnabled = true
            self.timer?.invalidate()
            self.verificationButton.setTitle("发送验证码", forState: .Normal)
        }else{
            self.verificationButton.setTitle("\(count)秒", forState: .Normal)
            count--
        }
    }
    func phonelogin() {
        self.noticeOnlyText("正在登录中")
        self.navigationController?.view.userInteractionEnabled = false
        CupProvider.request(.PhoneLogin(self.phoneTextField.text!)).filterSuccessfulStatusCodes().mapJSON().observeOn(MainScheduler.sharedInstance).subscribe(onNext: { (let json) -> Void in
            self.clearAllNotice()
            staticAccount = AccountModel.toModel(json as! [String : AnyObject])
            AccountModel.localSave()
            if staticIdentifier == nil {
                self.navigationController?.ks_pushViewController(CentralViewController())
            }else{
                UIApplication.sharedApplication().keyWindow!.rootViewController = R.storyboard.main.instance.instantiateInitialViewController()
            }
            }, onError: {
                self.clearAllNotice()
                self.navigationController?.view.userInteractionEnabled = true
                if let error = $0 as? NSError, let response = error.userInfo["data"] as? MoyaResponse {
                    self.noticeError(JSON(data: response.data)["message"].stringValue, autoClear: true)
                }
                
        }).addDisposableTo(disposeBag)
    }
    deinit{
        self.timer?.invalidate()
    }
    
}