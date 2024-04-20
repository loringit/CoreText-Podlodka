//
//  SlideController.swift
//  CoreTextAnimator
//
//  Created by Bulat Iakupov on 05/04/2024.
//

import UIKit

final class SliderViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet weak var drawableView: UIView!
    @IBOutlet weak var slider: UISlider!
    
    var textAnimator: TextAnimator?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        initTextAnimator()
        slider.value = 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textAnimator = nil
    }
    
    // MARK: TextAnimator
    
    private func initTextAnimator() {
        textAnimator = TextAnimator(referenceView: drawableView)
        textAnimator?.prepareForAnimation()
    }
    
    // MARK: IBActions
    
    @IBAction func didChangeSliderValue(sender: UISlider) {
        guard let textAnimator = textAnimator else { return }
        textAnimator.updatePathStrokeWithValue(value: sender.value)
    }
}

