//
//  GlobalFile.swift
//  HeyU
//
//  Created by Bekground on 24/01/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

let isLogin = UserDefaults.standard.bool(forKey: "isLogin")
var mobileNumber = UserDefaults.standard.value(forKey: "mobileNumber")

let SCREEN_WIDTH = UIScreen.main.bounds.size.width
let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
let isAnswer = UserDefaults.standard.bool(forKey: "isAnswer")

let AppID = "86c9b23e50f44786ab08fb1d925e9a62"

var AgoraKit: AgoraRtcEngineKit!
let isIncomingCall = UserDefaults.standard.bool(forKey: "isIncomingCall")
