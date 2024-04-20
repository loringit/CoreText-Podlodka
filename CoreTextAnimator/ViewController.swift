//
//  ViewController.swift
//  CoreTextAnimator
//
//  Created by Bulat Iakupov on 05/04/2024.
//

import UIKit

final class ViewController: UIViewController {
    // MARK: - Subviews
    
    @IBOutlet weak var drawableView: UIView!
    @IBOutlet weak var startAnimationButton: UIButton!
    @IBOutlet weak var stopAnimationButton: UIButton!
    
    @IBOutlet weak var backgroundSwitch: UISwitch! {
        didSet {
            backgroundSwitch.addAction(
                UIAction(handler: { [weak self] _ in
                    self?.textAnimator?.withBackground = self?.backgroundSwitch.isOn ?? true
                }),
                for: .valueChanged
            )
        }
    }
    
    @IBOutlet weak var strokeSwitch: UISwitch! {
        didSet {
            strokeSwitch.addAction(
                UIAction(handler: { [weak self] _ in
                    self?.textAnimator?.withStroke = self?.strokeSwitch.isOn ?? true
                }),
                for: .valueChanged
            )
        }
    }
    
    @IBOutlet weak var fontPicker: UIPickerView! {
        didSet {
            fontPicker.delegate = self
            fontPicker.dataSource = self
        }
    }
    
    @IBOutlet weak var fontSizeTextField: UITextField! {
        didSet {
            fontSizeTextField.delegate = self
            fontSizeTextField.addAction(
                UIAction(handler: { [weak self] _ in
                    let string = self?.fontSizeTextField.text ?? "50"
                    
                    self?.textAnimator?.fontSize = CGFloat(Double(string) ?? 50)
                }),
                for: .editingChanged
            )
        }
    }
    
    @IBOutlet weak var textToAnimateTextField: UITextField! {
        didSet {
            textToAnimateTextField.delegate = self
            textToAnimateTextField.addAction(
                UIAction(handler: { [weak self] _ in
                    let text = self?.textToAnimateTextField.text ?? ""
                    
                    self?.textAnimator?.textToAnimate = text.isEmpty ? "Podlodka" : text
                }),
                for: .editingChanged
            )
        }
    }
    
    // MARK: - Private properties
    
    private var textAnimator: TextAnimator?
    private var isAnimating = false
    private var chosenFontName = "Avenir" {
        didSet {
            textAnimator?.fontName = chosenFontName
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        initTextAnimator()
        updateUI()
        configureTapGesture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textAnimator = nil
    }
    
    // MARK: - TextAnimator
    
    private func initTextAnimator() {
        textAnimator = TextAnimator(referenceView: drawableView)
        textAnimator?.delegate = self
    }
    
    // MARK: - Tap gesture
    
    private func configureTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func tap(gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // MARK: - Appearance
    
    private func updateUI() {
        textToAnimateTextField.placeholder = textAnimator!.textToAnimate
        fontSizeTextField.placeholder = "\(textAnimator!.fontSize)"
        if let animatorFontName = textAnimator?.fontName {
            chosenFontName = animatorFontName
        }
        if let chosenFontIndex = UIFont.familyNames.firstIndex(of: chosenFontName) {
            fontPicker.selectRow(chosenFontIndex, inComponent: 0, animated: true)
        }
    }
    
    private func updateButtons() {
        startAnimationButton.isHidden = isAnimating
        stopAnimationButton.isHidden = !isAnimating
    }
    
    // MARK: - IBActions
    
    @IBAction func didPressStartAnimationButton(sender: UIButton) {
        startAnimation()
    }
    
    @IBAction func didPressStopAnimationButton() {
        stopAnimation()
    }
    
    // MARK: - Animations
    
    private func startAnimation() {
        textAnimator?.startAnimation()
    }
    
    private func stopAnimation() {
        textAnimator?.stopAnimation()
    }
}

// MARK: - UIPickerView delegate & dataSource

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return UIFont.familyNames.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        chosenFontName = UIFont.familyNames[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(
            string: UIFont.familyNames[row],
            attributes: [.foregroundColor: UIColor.label]
        )
    }
}

// MARK: - TextAnimator delegate

extension ViewController: TextAnimatorDelegate {
    func textAnimator(_ textAnimator: TextAnimator, animationDidStart animation: CAAnimation) {
        isAnimating = true
        updateButtons()
    }
    
    func textAnimator(_ textAnimator: TextAnimator, animationDidStop animation: CAAnimation) {
        isAnimating = false
        updateButtons()
    }
}

// MARK: - UITextField delegate

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

