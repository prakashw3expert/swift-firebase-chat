//
//  MemberCollectionCell.swift
//  HeyU
//
//  Created by Bekground on 01/02/17.
//  Copyright © 2017 Bekground. All rights reserved.
//

import UIKit

class MemberCollectionCell: UICollectionViewCell {

    @IBOutlet var memberImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.memberImage.layer.cornerRadius = 25
        self.memberImage.clipsToBounds = true
        
        self.memberImage.layer.borderColor = UIColor.init(red: 225.0/255.0, green: 28.0/255.30, blue: 39.0/255.0, alpha: 1.0).cgColor
        self.memberImage.layer.borderWidth = 1
        
    }

}
