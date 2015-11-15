//
//  FirstViewController.swift
//  Cup
//
//  Created by king on 15/10/11.
//  Copyright © 2015年 king. All rights reserved.
//

import UIKit
import RxSwift

class CupViewController: UITableViewController {
    var headerView = R.nib.cupHeaderView.firstView(nil, options: nil)
    var temperatureArray : [TemperatureModel] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = Colors.background
        let rightButton = UIBarButtonItem.init(barButtonSystemItem: .Add, target: self, action: "addTemperature")
//        self.navigationItem.rightBarButtonItem = rightButton
        self.tableView.registerNib(R.nib.temperatureTableViewCell)
        self.setTableHeaderView()
        self.tableView.estimatedRowHeight = 45
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.temperatureArray = TemperatureModel.getTemperatures()
        self.tableView.reloadData()
    }

    func setTableHeaderView() {
        headerView?.ks_height = 204
        self.tableView.tableHeaderView = headerView
    }
}
extension CupViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return temperatureArray.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let model = temperatureArray[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.temperatureTableViewCell.reuseIdentifier, forIndexPath: indexPath)!
        cell.backgroundColor = Colors.background
        cell.selectionStyle = .None
        cell.explanationLabel.text = model.explanation
        cell.temperatureLabel.text = "\(model.temperature)度"
        cell.openSwitch.on = model.open
        cell.openSwitch.rx_controlEvents(.TouchUpInside).subscribeNext{ [unowned cell,unowned self] in
            let on = cell.openSwitch.on
            if on {
                self.temperatureArray.forEach{
                    $0.open = false
                }
                model.open = on
                self.headerView?.meTemperaturelabel.text = "\(model.temperature)"
                tableView.reloadData()
            } else {
                model.open = on
            }
        }
        return cell
    }
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(17)
        label.text = "恒温设定"
        label.sizeToFit()
        headerView.addSubview(label)
        label.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(17)
            make.centerY.equalTo(headerView)
        }
        let button = UIButton()
        button.setImage(R.image.plus, forState: .Normal)
        headerView.addSubview(button)
        button.snp_makeConstraints { (make) -> Void in
            make.width.height.equalTo(27)
            make.right.equalTo(-12)
            make.centerY.equalTo(0)
        }
        button.rx_tap.subscribeNext { [unowned self] in
            let vc = R.nib.temperatureViewController.firstView(nil, options: nil)!
            self.presentViewController(vc, animated: true, completion: nil)
        }
        return headerView
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 46
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "恒温设定"
    }
}

