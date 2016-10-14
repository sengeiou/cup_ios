//
//  WaterModel.swift
//  Cup
//
//  Created by king on 16/9/7.
//  Copyright © 2016年 king. All rights reserved.
//

import Foundation
import KSJSONHelp
import SwiftDate

class WaterModel: NSObject,Model,Storable,PrimaryKeyProtocol {
    var date = "2016-01-10"
    var weekOfYear = 01
    var hour = 08
    var minute = 0
    var second = 0
    var amount = 0
    override required init() {
        super.init()
    }
    static func primaryKeys() -> Set<String> {
        return ["date","hour","minute","second"]
    }
    static func save(_ date: Date,amount: Int) {
        let model = WaterModel()
        model.date = date.ks.string(fromFormat:"yyyy-MM-dd")
        model.weekOfYear = date.weekOfYear
        model.hour = date.hour
        model.minute = date.minute
        model.second = date.second
        model.amount = amount
        model.save()
    }
    ///0:日,1:周,2:月
    static func fetch(_ date: Date,type:Int=0) -> [WaterModel]? {
        if type == 0 {
            let dic = ["date": date.ks.string(fromFormat:"yyyy-MM-dd")]
            return WaterModel.fetch(dic: dic)
        } else {
            let beginDate = date - (type == 1 ? 7.days : 30.days)
            let filter = CompositeFilter().greater("date", value: beginDate.ks.string(fromFormat:"yyyy-MM-dd")).lessOrEqual("date",value:date.ks.string(fromFormat:"yyyy-MM-dd"))
            return WaterModel.fetch(filter)
        }
    }

}
