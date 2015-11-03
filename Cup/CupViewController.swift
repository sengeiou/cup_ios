//
//  FirstViewController.swift
//  Cup
//
//  Created by king on 15/10/11.
//  Copyright © 2015年 king. All rights reserved.
//

import UIKit
import RxSwift
class CupViewController: UIViewController {
    let bag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        self.tabBarItem.imageInsets = UIEdgeInsetsMake(5.5, 0, -5.5, 0)

        CupProvider.request(.Jsonfeed).mapJSON().subscribeNext { (let json) -> Void in
            print(json)
        }.addDisposableTo(bag)
        CupProvider.request(.Add("wang","1")).mapString().subscribe { (event) -> Void in
            print(event)
        }.addDisposableTo(bag)
        CupProvider.request(.TestError).subscribe { (event) -> Void in
            print(event)
        }.addDisposableTo(bag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

