//
//  LabelViewController.swift
//  CoreTextAnimator
//
//  Created by Bulat Iakupov on 15/04/2024.
//

import UIKit

final class LabelViewController: UIViewController {
    // MARK: - Subviews
    
    @IBOutlet weak var strokeLabel: UILabel! {
        didSet {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            strokeLabel.attributedText = NSAttributedString(
                string: "Podlodka",
                attributes: [
                    .foregroundColor: UIColor.purple,
                    .paragraphStyle: paragraphStyle,
                    .strokeColor: UIColor.black,
                    .strokeWidth: -7,
                    .font: UIFont(name: "Avenir", size: 50)!,
                ]
            )
        }
    }
    
    @IBOutlet weak var backgroundLabel: UILabel! {
        didSet {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            backgroundLabel.attributedText = NSAttributedString(
                string: "Podlodka",
                attributes: [
                    .foregroundColor: UIColor.purple,
                    .paragraphStyle: paragraphStyle,
                    .font: UIFont(name: "Avenir", size: 50)!,
                    .backgroundColor: UIColor.systemBlue
                ]
            )
        }
    }
}
