//
//  TemperatureViewController.swift
//  Cup
//
//  Created by king on 15/11/10.
//  Copyright © 2015年 king. All rights reserved.
//

import UIKit

class TemperatureViewController: UIViewController {
    
    @IBOutlet weak var temperaturePickerView: UIPickerView!
    @IBOutlet weak var explanationTextField: UITextField!
    var pickerData = [Array(20...70).map{"\($0)度"}]
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func saveAction(sender: AnyObject) {
        if let text = explanationTextField.text where text.length > 0 {
            let model = TemperatureModel()
            model.explanation = text
            model.temperature = temperaturePickerView.selectedRowInComponent(0)+20
            TemperatureModel.addTemperature(model)
            self.dismissViewControllerAnimated(true, completion: nil)
        }else{
            self.noticeInfo("温度描述不能为空")
        }
    }
}
extension TemperatureViewController:UIPickerViewDataSource, UIPickerViewDelegate {
    // MARK - Picker delegate
    func pickerView(_pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData[component].count
    }
    
    func numberOfComponentsInPickerView(_pickerView: UIPickerView) -> Int {
        return pickerData.count
    }
    
    
    func pickerView(_pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[component][row]
    }

}