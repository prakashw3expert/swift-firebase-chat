//
//  SettingVC.swift
//  HeyU
//
//  Created by BekGround-2 on 10/03/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

protocol SettingsVCDelegate: NSObjectProtocol {
    func settingsVC(_ settingsVC: SettingVC, didSelectProfile profile: AgoraRtcVideoProfile)
}

class SettingVC: UIViewController {
    
    @IBOutlet weak var profileTableView: UITableView!
    
    var videoProfile: AgoraRtcVideoProfile! {
        didSet {
            profileTableView?.reloadData()
        }
    }
    weak var delegate: SettingsVCDelegate?
    
    fileprivate let profiles: [AgoraRtcVideoProfile] = AgoraRtcVideoProfile.list()
    
    @IBAction func doConfirmPressed(_ sender: UIButton) {
        delegate?.settingsVC(self, didSelectProfile: videoProfile)
    }
}

extension SettingVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileCell", for: indexPath) as! ProfileCell
        let selectedProfile = profiles[indexPath.row]
        cell.update(with: selectedProfile, isSelected: (selectedProfile == videoProfile))
        
        return cell
    }
}

extension SettingVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProfile = profiles[indexPath.row]
        videoProfile = selectedProfile
    }
}

private extension AgoraRtcVideoProfile {
    static func list() -> [AgoraRtcVideoProfile] {
        return AgoraRtcVideoProfile.validProfileList()
    }
}

