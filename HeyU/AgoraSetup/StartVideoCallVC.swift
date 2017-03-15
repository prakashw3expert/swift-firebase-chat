//
//  StartVideoCallVC.swift
//  HeyU
//
//  Created by BekGround-2 on 10/03/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit
import Firebase

protocol RoomVCDelegate: class {
    func roomVCNeedClose(_ roomVC: StartVideoCallVC)
}

class StartVideoCallVC: UIViewController {
    
    
    var myCallingRef: FIRDatabaseReference?
    //MARK: IBOutlet
    @IBOutlet weak var containerView: UIView!
    @IBOutlet var flowViews: [UIView]!
    @IBOutlet weak var roomNameLabel: UILabel!
    
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var messageTableContainerView: UIView!
    
    @IBOutlet weak var messageButton: UIButton!
    
    @IBOutlet weak var muteVideoButton: UIButton!
    @IBOutlet weak var muteAudioButton: UIButton!
    
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var speakerButton: UIButton!
    
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet var LblShowCallingTime: UILabel!
    
    @IBOutlet weak var messageInputerView: UIView!
    @IBOutlet weak var messageInputerBottom: NSLayoutConstraint!
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet var backgroundTap: UITapGestureRecognizer!
    @IBOutlet var backgroundDoubleTap: UITapGestureRecognizer!
    
    //MARK: public var
    var counter = 0
    var timeer = Timer()
    var roomName: String?
    var myRef: FIRDatabaseReference?
    var encryptionSecret: String?
    var encryptionType: EncryptionType?
    var videoProfile: AgoraRtcVideoProfile?
    weak var delegate: RoomVCDelegate?
    
    //MARK: hide & show
    fileprivate var shouldHideFlowViews = false {
        didSet {
            if let flowViews = flowViews {
                for view in flowViews {
                    view.isHidden = shouldHideFlowViews
                }
            }
        }
    }
    
    //MARK: engine & session
    var agoraKit: AgoraRtcEngineKit!
    fileprivate var videoSessions = [VideoSession]() {
        didSet {
            updateInterface(with: self.videoSessions, targetSize: containerView.frame.size, animation: true)
        }
    }
    fileprivate var doubleClickFullSession: VideoSession? {
        didSet {
            if videoSessions.count >= 3 && doubleClickFullSession != oldValue {
                updateInterface(with: videoSessions, targetSize: containerView.frame.size, animation: true)
            }
        }
    }
    fileprivate let videoViewLayouter = VideoViewLayouter()
    fileprivate var dataChannelId: Int = -1
    
    //MARK: alert
    fileprivate weak var currentAlert: UIAlertController?
    
    //MARK: mute
    fileprivate var audioMuted = false {
        didSet {
            muteAudioButton?.setImage(UIImage(named: audioMuted ? "btn_mute_blue" : "btn_mute"), for: UIControlState())
            agoraKit.muteLocalAudioStream(audioMuted)
        }
    }
    fileprivate var videoMuted = false {
        didSet {
            muteVideoButton?.setImage(UIImage(named: videoMuted ? "btn_video" : "btn_voice"), for: UIControlState())
            cameraButton?.isHidden = videoMuted
            speakerButton?.isHidden = !videoMuted
            
            agoraKit.muteLocalVideoStream(videoMuted)
            setVideoMuted(videoMuted, forUid: 0)
            
            updateSelfViewVisiable()
        }
    }
    
    //MARK: speaker
    fileprivate var speakerEnabled = true {
        didSet {
            speakerButton?.setImage(UIImage(named: speakerEnabled ? "btn_speaker_blue" : "btn_speaker"), for: UIControlState())
            speakerButton?.setImage(UIImage(named: speakerEnabled ? "btn_speaker" : "btn_speaker_blue"), for: .highlighted)
            
            agoraKit.setEnableSpeakerphone(speakerEnabled)
        }
    }
    
    //MARK: filter
    fileprivate var isFiltering = false {
        didSet {
            guard let agoraKit = agoraKit else {
                return
            }
            
            if isFiltering {
                AGVideoPreProcessing.registerVideoPreprocessing(agoraKit)
                filterButton?.setImage(UIImage(named: "btn_filter_blue"), for: UIControlState())
            } else {
                AGVideoPreProcessing.deregisterVideoPreprocessing(agoraKit)
                filterButton?.setImage(UIImage(named: "btn_filter"), for: UIControlState())
            }
        }
    }
    
    //MARK: text message
    fileprivate var chatMessageVC: ChatMessageVC?
    fileprivate var isInputing = false {
        didSet {
            if isInputing {
                messageTextField?.becomeFirstResponder()
            } else {
                messageTextField?.resignFirstResponder()
            }
            messageInputerView?.isHidden = !isInputing
            messageButton?.setImage(UIImage(named: isInputing ? "btn_message_blue" : "btn_message"), for: UIControlState())
        }
    }
    
    //MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomNameLabel.text = "\(roomName!)"
        backgroundTap.require(toFail: backgroundDoubleTap)
        addKeyboardObserver()
        
        loadAgoraKit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
       
    }
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else {
            return
        }
        
        switch segueId {
        case "VideoVCEmbedChatMessageVC":
            chatMessageVC = segue.destination as? ChatMessageVC
        default:
            break
        }
    }
    
    //MARK: - user action
    @IBAction func doMessagePressed(_ sender: UIButton) {
        isInputing = !isInputing
    }
    
    @IBAction func doCloseMessagePressed(_ sender: UIButton) {
        isInputing = false
    }
    
    @IBAction func doMuteVideoPressed(_ sender: UIButton) {
        videoMuted = !videoMuted
    }
    
    @IBAction func doMuteAudioPressed(_ sender: UIButton) {
        audioMuted = !audioMuted
    }
    
    @IBAction func doCameraPressed(_ sender: UIButton) {
        agoraKit.switchCamera()
    }
    
    @IBAction func doSpeakerPressed(_ sender: UIButton) {
        speakerEnabled = !speakerEnabled
    }
    
    @IBAction func doFilterPressed(_ sender: UIButton) {
        isFiltering = !isFiltering
    }
    
    @IBAction func doClosePressed(_ sender: UIButton) {
        leaveChannel()
    }
    
    @IBAction func doBackTapped(_ sender: UITapGestureRecognizer) {
        if !isInputing {
            shouldHideFlowViews = !shouldHideFlowViews
        }
    }
    
    @IBAction func doBackDoubleTapped(_ sender: UITapGestureRecognizer) {
        if doubleClickFullSession == nil {
            //将双击到的session全屏
            if let tappedIndex = videoViewLayouter.reponseViewIndex(of: sender.location(in: containerView)) {
                doubleClickFullSession = videoSessions[tappedIndex]
            }
        } else {
            doubleClickFullSession = nil
        }
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .all
    }
    
    
    
    //Call Timer.......
    
    func CallTimerSetCallTime(){
        
        timeer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(StartTimer), userInfo: nil, repeats: true)
        
    
    }
    
    func StartTimer(){
        
        counter += 1
        LblShowCallingTime.isHidden = false
        LblShowCallingTime.text = seconds2Timestamp(intSeconds: counter)
        print(counter)
    }
    func seconds2Timestamp(intSeconds:Int)->String {
        let secs:Int = intSeconds%60
        let mins:Int = intSeconds/60
        let hours:Int = mins/60
        
        
        if(mins >= 60)
        {
            let mint = mins%60
            let strTimestamp:String = ((hours<10) ? "0" : "") + String(hours) + ":" + ((mint<10) ? "0" : "") + String(mint) + ":" + ((secs<10) ? "0" : "") + String(secs)
            return strTimestamp
        }
        
        let strTimestamp:String = ((hours<10) ? "0" : "") + String(hours) + ":" + ((mins<10) ? "0" : "") + String(mins) + ":" + ((secs<10) ? "0" : "") + String(secs)
        return strTimestamp
    }
    
}

//MARK: - textFiled
extension StartVideoCallVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text , !text.isEmpty {
            send(text: text)
            textField.text = nil
        }
        return true
    }
}

//MARK: - private
private extension StartVideoCallVC {
    func addKeyboardObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: nil) { [weak self] notify in
            guard let strongSelf = self, let userInfo = (notify as NSNotification).userInfo,
                let keyBoardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue,
                let durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber else {
                    return
            }
            
            let keyBoardBounds = keyBoardBoundsValue.cgRectValue
            let duration = durationValue.doubleValue
            let deltaY = keyBoardBounds.size.height
            
            if duration > 0 {
                var optionsInt: UInt = 0
                if let optionsValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
                    optionsInt = optionsValue.uintValue
                }
                let options = UIViewAnimationOptions(rawValue: optionsInt)
                
                UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                    strongSelf.messageInputerBottom.constant = deltaY
                    strongSelf.view?.layoutIfNeeded()
                }, completion: nil)
                
            } else {
                strongSelf.messageInputerBottom.constant = deltaY
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil) { [weak self] notify in
            guard let strongSelf = self else {
                return
            }
            
            let duration: Double
            if let userInfo = (notify as NSNotification).userInfo, let durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber {
                duration = durationValue.doubleValue
            } else {
                duration = 0
            }
            
            if duration > 0 {
                var optionsInt: UInt = 0
                if let userInfo = (notify as NSNotification).userInfo, let optionsValue = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber {
                    optionsInt = optionsValue.uintValue
                }
                let options = UIViewAnimationOptions(rawValue: optionsInt)
                
                UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                    strongSelf.messageInputerBottom.constant = 0
                    strongSelf.view?.layoutIfNeeded()
                }, completion: nil)
                
            } else {
                strongSelf.messageInputerBottom.constant = 0
            }
        }
    }
    
    func updateInterface(with sessions: [VideoSession], targetSize: CGSize, animation: Bool) {
        if animation {
            UIView.animate(withDuration: 0.3, delay: 0, options: .beginFromCurrentState, animations: {[weak self] () -> Void in
                self?.updateInterface(with: sessions, targetSize: targetSize)
                self?.view.layoutIfNeeded()
                }, completion: nil)
        } else {
            updateInterface(with: sessions, targetSize: targetSize)
        }
    }
    
    func updateInterface(with sessions: [VideoSession], targetSize: CGSize) {
        guard !sessions.isEmpty else {
            return
        }
        
        let selfSession = sessions.first!
        videoViewLayouter.selfView = selfSession.hostingView
        videoViewLayouter.selfSize = selfSession.size
        videoViewLayouter.targetSize = targetSize
        var peerVideoViews = [VideoView]()
        for i in 1..<sessions.count {
            peerVideoViews.append(sessions[i].hostingView)
        }
        videoViewLayouter.videoViews = peerVideoViews
        videoViewLayouter.fullView = doubleClickFullSession?.hostingView
        videoViewLayouter.containerView = containerView
        
        videoViewLayouter.layoutVideoViews()
        
        updateSelfViewVisiable()
        
        //只有三人及以上时才能切换布局形式
        if sessions.count >= 3 {
            backgroundDoubleTap.isEnabled = true
        } else {
            backgroundDoubleTap.isEnabled = false
            doubleClickFullSession = nil
        }
    }
    
    func setIdleTimerActive(_ active: Bool) {
        UIApplication.shared.isIdleTimerDisabled = !active
    }
    
    func fetchSession(of uid: UInt) -> VideoSession? {
        for session in videoSessions {
            if session.uid == uid {
                return session
            }
        }
        
        return nil
    }
    
    func videoSession(of uid: UInt) -> VideoSession {
        if let fetchedSession = fetchSession(of: uid) {
            return fetchedSession
        } else {
            let newSession = VideoSession(uid: uid)
            videoSessions.append(newSession)
            return newSession
        }
    }
    
    func setVideoMuted(_ muted: Bool, forUid uid: UInt) {
        fetchSession(of: uid)?.isVideoMuted = muted
    }
    
    func updateSelfViewVisiable() {
        guard let selfView = videoSessions.first?.hostingView else {
            return
        }
        
        if videoSessions.count == 2 {
            selfView.isHidden = videoMuted
        } else {
            selfView.isHidden = false
        }
    }
    
    func alert(string: String) {
        guard !string.isEmpty else {
            return
        }
        chatMessageVC?.append(alert: string)
    }
}

//MARK: - engine
private extension StartVideoCallVC {
    func loadAgoraKit() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: KeyCenter.AppId, delegate: self)
        agoraKit.setChannelProfile(.channelProfile_Communication)
        agoraKit.enableVideo()
        agoraKit.setVideoProfile(videoProfile!, swapWidthAndHeight: false)
        
        addLocalSession()
        agoraKit.startPreview()
        if let encryptionType = encryptionType, let encryptionSecret = encryptionSecret, !encryptionSecret.isEmpty {
            agoraKit.setEncryptionMode(encryptionType.modeString())
            agoraKit.setEncryptionSecret(encryptionSecret)
        }
        
        let code = agoraKit.joinChannel(byKey: nil, channelName: roomName, info: nil, uid: 0, joinSuccess: nil)
        
        if code == 0 {
            setIdleTimerActive(false)
        } else {
            DispatchQueue.main.async(execute: {
                self.alert(string: "Join channel failed: \(code)")
            })
        }
        
        agoraKit.createDataStream(&dataChannelId, reliable: true, ordered: true)
    }
    
    func addLocalSession() {
        let localSession = VideoSession.localSession()
        videoSessions.append(localSession)
        agoraKit.setupLocalVideo(localSession.canvas)
        
        if let mediaInfo = MediaInfo(videoProfile: videoProfile!) {
            localSession.mediaInfo = mediaInfo
        }
    }
    
    func leaveChannel() {
        
        agoraKit.setupLocalVideo(nil)
        agoraKit.leaveChannel(nil)
        agoraKit.stopPreview()
        isFiltering = false
        timeer.invalidate()
        counter = 0
        for session in videoSessions {
            session.hostingView.removeFromSuperview()
        }
        videoSessions.removeAll()
        myCallingRef?.child("Calling").removeValue()
        myRef?.child("Calling").removeValue()
        setIdleTimerActive(true)
        delegate?.roomVCNeedClose(self)
       
        dismiss(animated: true, completion: nil)
    }
    
    func send(text: String) {
        if dataChannelId > 0, let data = text.data(using: String.Encoding.utf8) {
            agoraKit.sendStreamMessage(dataChannelId, data: data)
            chatMessageVC?.append(chat: text, fromUid: 0)
        }
    }
}

//MARK: - engine delegate
extension StartVideoCallVC: AgoraRtcEngineDelegate {
    func rtcEngineConnectionDidInterrupted(_ engine: AgoraRtcEngineKit!) {
        alert(string: "Connection Interrupted")
    }
    
    func rtcEngineConnectionDidLost(_ engine: AgoraRtcEngineKit!) {
        alert(string: "Connection Lost")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didOccurError errorCode: AgoraRtcErrorCode) {
        //
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        
        
        let userSession = videoSession(of: uid)
        let sie = size.fixedSize(with: containerView.bounds.size)
        userSession.size = sie
        userSession.updateMediaInfo(resolution: size)
        agoraKit.setupRemoteVideo(userSession.canvas)
    }
    
    
    func rtcEngineMediaEngineDidStartCall(_ engine: AgoraRtcEngineKit!) {
        print("Star Call")
        CallTimerSetCallTime()
    }
    //first local video frame
    func rtcEngine(_ engine: AgoraRtcEngineKit!, firstLocalVideoFrameWith size: CGSize, elapsed: Int) {
        if let selfSession = videoSessions.first {
            let fixedSize = size.fixedSize(with: containerView.bounds.size)
            selfSession.size = fixedSize
            updateInterface(with: videoSessions, targetSize: containerView.frame.size, animation: false)
        }
    }
    
    //user offline
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didOfflineOfUid uid: UInt, reason: AgoraRtcUserOfflineReason) {
        var indexToDelete: Int?
        for (index, session) in videoSessions.enumerated() {
            if session.uid == uid {
                indexToDelete = index
            }
            
        }
        
        if let indexToDelete = indexToDelete {
            let deletedSession = videoSessions.remove(at: indexToDelete)
            deletedSession.hostingView.removeFromSuperview()
            if let doubleClickFullSession = doubleClickFullSession , doubleClickFullSession == deletedSession {
                self.doubleClickFullSession = nil
            }
        }
        
        leaveChannel()
    }
    
    //video muted
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didVideoMuted muted: Bool, byUid uid: UInt) {
        setVideoMuted(muted, forUid: uid)
    }
    
    //remote stat
    func rtcEngine(_ engine: AgoraRtcEngineKit!, remoteVideoStats stats: AgoraRtcRemoteVideoStats!) {
        if let stats = stats, let session = fetchSession(of: stats.uid) {
            session.updateMediaInfo(resolution: CGSize(width: CGFloat(stats.width), height: CGFloat(stats.height)), bitRate: Int(stats.receivedBitrate), fps: Int(stats.receivedFrameRate))
        }
    }
    
    //data channel
    func rtcEngine(_ engine: AgoraRtcEngineKit!, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data!) {
        guard let data = data, let string = String(data: data, encoding: String.Encoding.utf8) , !string.isEmpty else {
            return
        }
        chatMessageVC?.append(chat: string, fromUid: Int64(uid))
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit!, didOccurStreamMessageErrorFromUid uid: UInt, streamId: Int, error: Int, missed: Int, cached: Int) {
        print("Data channel error: \(error), missed: \(missed), cached: \(cached)\n")
    }
}

//MARK: - rotation
extension StartVideoCallVC {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        for session in videoSessions {
            if let sessionSize = session.size {
                session.size = sessionSize.fixedSize(with: size)
            }
        }
        updateInterface(with: videoSessions, targetSize: size, animation: true)
    }
}
