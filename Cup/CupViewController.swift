//
//  FirstViewController.swift
//  Cup
//
//  Created by king on 15/10/11.
//  Copyright © 2015年 king. All rights reserved.
//

import UIKit
import RxSwift
import CoreBluetooth
import Async
import KSSwiftExtension
class CupViewController: UITableViewController {
    let disposeBag = DisposeBag()
    var headerView = R.nib.cupHeaderView.firstView(owner: nil, options: nil)
    var temperatureArray : [TemperatureModel] = []
    var central: CBCentralManager!
    var peripheral: CBPeripheral?
    var characteristic: Variable<CBCharacteristic?> = Variable(nil)
    var selectedIndex: Int?
    var timer: NSTimer?
    var durationTimer: NSTimer?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = Colors.background
        self.tableView.registerNib(R.nib.temperatureTableViewCell)
        self.setTableHeaderView()
        self.tableView.estimatedRowHeight = 45
        self.setUpCentral()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(askTemperature), forControlEvents: UIControlEvents.ValueChanged)
        //修改下拉刷新标题
        refreshControl?.attributedTitle = NSAttributedString(string: "释放刷新")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.temperatureArray = TemperatureModel.getTemperatures()
        if let _ = self.selectedIndex {
            var i = 0
            var hasSet = false
            self.temperatureArray.forEach {
                if $0.open {
                    if !hasSet {
                        self.selectedIndex = i
                        hasSet = true
                    } else {
                        $0.open = false
                    }
                }
                i+=1
            }
            self.sendTemperature()
        } else {
            self.temperatureArray.forEach {
                if $0.open {
                    $0.open = false
                    $0.save()
                }
            }
        }
        self.tableView.reloadData()
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        endRefreshing()
    }
    
    func setTableHeaderView() {
        headerView?.ks_height = 204
        self.tableView.tableHeaderView = headerView
        let view = UIView(frame: CGRectMake(0,204,self.view.ks_width,self.view.ks_height))
        view.alpha = 0.5
        view.backgroundColor = UIColor.blackColor()
        self.view.addSubview(view)
        let tapGestureRecognizer = UITapGestureRecognizer()
        headerView?.meTemperaturelabel.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.rx_event.subscribeNext{ [unowned self] _ in
            if view.superview != nil {
                view.removeFromSuperview()
            }else{
                self.view.addSubview(view)
                self.temperatureArray.forEach{
                    $0.open = false
                }
                self.tableView.reloadData()
            }
            }.addDisposableTo(disposeBag)
        self.characteristic.asObservable().subscribeNext{
            if $0 != nil {
                view.removeFromSuperview()
            }
            }.addDisposableTo(disposeBag)
    }
    deinit {
        self.timer?.invalidate()
        self.timer = nil
        self.durationTimer?.invalidate()
        self.durationTimer = nil
        if let peripheral = self.peripheral {
            self.central.cancelPeripheralConnection(peripheral)
        }
    }
}
extension CupViewController {
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return temperatureArray.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let model = temperatureArray[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(R.nib.temperatureTableViewCell, forIndexPath: indexPath)!
        cell.backgroundColor = Colors.background
        cell.selectionStyle = .None
        cell.explanationLabel.text = model.explanation
        cell.temperatureLabel.text = "\(model.temperature)度"
        cell.openSwitch.on = model.open
        cell.openSwitch.rx_controlEvent(.TouchUpInside).subscribeNext{ [unowned cell,unowned self] in
            let on = cell.openSwitch.on
            if on {
                if self.characteristic.value == nil {
                    self.alterCentralViewController()
                    Async.main(after: 0.35) {
                        cell.openSwitch.on = false
                    }
                } else {
                    self.temperatureArray.forEach{
                        $0.open = false
                    }
                    model.open = on
                    tableView.reloadData()
                    self.selectedIndex = indexPath.row
                    self.pleaseWait("正在下达指令 请稍后")
                    self.sendTemperature()
                }
            } else {
                model.open = on
                self.selectedIndex = nil
            }
            }.addDisposableTo(cell.disposeBag)
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
        button.setImage(UIImage(named: R.image.plus.name), forState: .Normal)
        headerView.addSubview(button)
        button.snp_makeConstraints { (make) -> Void in
            make.width.height.equalTo(27)
            make.right.equalTo(-12)
            make.centerY.equalTo(0)
        }
        if self.temperatureArray.count >= 5 {
            button.removeFromSuperview()
        }
        button.rx_tap.subscribeNext { [unowned self] in
            let vc = R.nib.temperatureViewController.firstView(owner: nil, options: nil)!
            self.navigationController?.presentViewController(vc, animated: true, completion: nil)
        }.addDisposableTo(self.disposeBag)
        return headerView
    }
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "恒温设定"
    }
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath){
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let model = self.temperatureArray[indexPath.row]
        let editAction = UITableViewRowAction(style: .Default, title: "编辑") {
           (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let vc = R.nib.temperatureViewController.firstView(owner: nil, options: nil)!
            vc.model = model
            self.navigationController?.presentViewController(vc, animated: true, completion: nil)
        }
        let deleteAction = UITableViewRowAction(style: .Default, title: "删除") {[unowned self]
            (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            model.delete()
            self.temperatureArray.removeAtIndex(indexPath.row)
            self.tableView.reloadData()
        }
        editAction.backgroundColor = Colors.black
        deleteAction.backgroundColor = Colors.black
        return [deleteAction,editAction]
    }
}
extension CupViewController {
    func setUpCentral() {
        self.central = CBCentralManager(delegate: self, queue: nil)
    }
    override func scanForPeripherals(central: CBCentralManager) {
        if let staticIdentifier = staticIdentifier, identifier = NSUUID(UUIDString: staticIdentifier) {
            self.durationTimer = NSTimer.scheduledTimerWithTimeInterval(15, target: self, selector: #selector(durationTimerElapsed), userInfo: nil, repeats: false)
            let peripherals = self.central.retrievePeripheralsWithIdentifiers([identifier])
            if peripherals.count > 0 {
                didDiscoverPeripheral(peripherals[0])
            }
        }else{
            alterCentralViewController()
        }
    }
    @objc private func durationTimerElapsed() {
        self.durationTimer?.invalidate()
        self.durationTimer = nil
        if self.characteristic.value == nil {
            let alertController = UIAlertController(title: "找不到之前设定的蓝牙的设备，是否要重新扫描，设定蓝牙设备", message: nil, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "是", style: UIAlertActionStyle.Default){
                (action: UIAlertAction!) -> Void in
                self.navigationController?.pushViewController(CentralViewController(), animated: true)
            }
            let cancelAction = UIAlertAction(title: "否", style: .Cancel, handler: nil)
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            presentViewController(alertController, animated: true, completion: nil)
            
        }
    }
    
    override func didDiscoverPeripheral(peripheral: CBPeripheral) {
        if peripheral.identifier.UUIDString == staticIdentifier {
            self.peripheral = peripheral
            self.central.connectPeripheral(peripheral, options: nil)
            self.central.stopScan()
        }
    }
    override func didDiscoverCharacteristicsForService(characteristic: CBCharacteristic) {
        if characteristic.properties.contains([.Notify]) {
            self.peripheral?.setNotifyValue(true, forCharacteristic: characteristic)
        }
        if characteristic.properties.contains([.Write]) {
            self.characteristic.value = characteristic
            self.timer = NSTimer.scheduledTimerWithTimeInterval(60*5, target: self, selector: #selector(askTemperature), userInfo: nil, repeats: true)
            self.timer?.fire()
            //连接通过之后，发送一下。让杯子叫一下
            let data = NSMutableData()
            data.appendUInt8(0x3a)
            data.appendUInt8(0x11)
            data.appendUInt16(0x00)
            data.appendUInt16(0x00)
            data.appendUInt8(0x11)
            data.appendUInt8(0x0a)
            self.peripheral?.writeValue(data, forCharacteristic: characteristic, type: .WithResponse)
        }
    }
    
    override var serviceUUIDs: [CBUUID]? {
        get{
            return [CBUUID(string: "FFE0"),CBUUID(string: "FFE5")]
        }
    }
    override func characteristicUUIDs(service: CBUUID) -> [CBUUID]? {
        //监听的通道
        if service.UUIDString == "FFE0" {
            return [CBUUID(string: "FFE4")]
        }else  if service.UUIDString == "FFE5" {
            return [CBUUID(string: "FFE9")]
        }
        return nil
    }
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        guard let data = characteristic.value else {
            return
        }
        let bytes = UnsafePointer<UInt8>(data.bytes)
        guard  bytes[0] == 0x3a else {
            return
        }
        ///设置温度返回
        if bytes[1] == 0x88 {
            Async.main(after: 1){
                self.clearAllNotice()
            }
            guard let selectedIndex = self.selectedIndex else {
                return
            }
            let temperature = self.temperatureArray[selectedIndex].temperature
            self.headerView?.meTemperaturelabel.text = "\(temperature)"
            self.headerView?.meExplanation.text = self.temperatureArray[selectedIndex].explanation
            if let text = self.headerView?.cupTemperaturelabel.text,cupTemperature = Int(text) {
                if abs(cupTemperature - temperature) <= 1 {
                    self.headerView?.cupTemperatureImageView.image = R.image.已恒温()
                    let alertController = UIAlertController(title: "亲! 水温已到达最适宜度数!", message: "请及时享用哦。", preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: nil)
                    alertController.addAction(okAction)
                    presentViewController(alertController, animated: true, completion: nil)
                }else{
                    self.headerView?.cupTemperatureImageView.image = R.image.恒温中()
                }
                
            }
        }else if bytes[1] == 0x44 {
            self.noticeError("校验码错误")
        }else if bytes[1] == 0x01 || bytes[1] == 0x02 {
            //0x01是达到设置的温度 蓝牙自动返回
            //查询温度返回
            if bytes[1] == 0x02  {
                endRefreshing()
            }
            var cupTemperature: UInt16 = 0
            data.getBytes(&cupTemperature, range: NSMakeRange(2,2))
            cupTemperature =  (cupTemperature / 10)
            self.headerView?.cupTemperaturelabel.text = "\(cupTemperature)"
            guard let selectedIndex = self.selectedIndex else {
                return
            }
            let temperature = self.temperatureArray[selectedIndex].temperature
            if abs(Int(cupTemperature) - temperature) <= 1  {
                self.headerView?.cupTemperatureImageView.image = R.image.已恒温()
                let alertController = UIAlertController(title: "亲! 水温已到达最适宜度数!", message: "请及时享用哦。", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: nil)
                alertController.addAction(okAction)
                presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)
    {
        self.timer?.invalidate()
        self.timer = nil
        self.durationTimer?.invalidate()
        self.durationTimer = nil
        if let _ = error {
            self.central.connectPeripheral(peripheral, options: nil)
        }
    }
    func alterCentralViewController() {
        let alertController = UIAlertController(title: "您还没有关联水杯设备,是否现在进行关联", message: nil, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "是", style: UIAlertActionStyle.Default){
            (action: UIAlertAction!) -> Void in
            self.navigationController?.pushViewController(CentralViewController(), animated: true)
        }
        let cancelAction = UIAlertAction(title: "否", style: .Cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
        
    }
    func sendTemperature() {
        if let characteristic = self.characteristic.value, selectedIndex = self.selectedIndex {
            let data = NSMutableData()
            data.appendUInt8(0x3a)
            data.appendUInt8(0x01)
            var val = UInt16(self.temperatureArray[selectedIndex].temperature * 10)
            data.appendBytes(&val, length: sizeofValue(val))
            data.appendUInt16(0x00)
            let bytes = UnsafePointer<UInt8>(data.bytes)
            data.appendUInt8(bytes[1] + bytes[2] + bytes[3] + bytes[4] + bytes[5])
            data.appendUInt8(0x0a)
            self.peripheral?.writeValue(data, forCharacteristic: characteristic, type: .WithResponse)
        }
    }
    func askTemperature() {
        if let characteristic = self.characteristic.value {
            let data = NSMutableData()
            data.appendUInt8(0x3a)
            data.appendUInt8(0x02)
            data.appendUInt16(0x00)
            data.appendUInt16(0x00)
            data.appendUInt8(0x02)
            data.appendUInt8(0x0a)
            self.peripheral?.writeValue(data, forCharacteristic: characteristic, type: .WithResponse)
        }
        refreshControl?.attributedTitle = NSAttributedString(string: "刷新中")
    }
}
extension UITableViewController {
    func endRefreshing() {
        refreshControl?.endRefreshing()
        refreshControl?.attributedTitle = NSAttributedString(string: "释放刷新")
    }
}