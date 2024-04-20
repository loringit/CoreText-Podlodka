//
//  TextAnimator.swift
//  CoreTextAnimator
//
//  Created by Bulat Iakupov on 05/04/2024.
//

import UIKit
import CoreFoundation

protocol TextAnimatorDelegate {
    func textAnimator(_ textAnimator: TextAnimator, animationDidStart animation: CAAnimation)
    func textAnimator(_ textAnimator: TextAnimator, animationDidStop animation: CAAnimation)
}

class TextAnimator: NSObject {
    
    // MARK: - Internal properties
    
    var fontName = "Avenir" {
        didSet {
            setupPathLayer()
        }
    }
    var fontSize: CGFloat = 50.0 {
        didSet {
            setupPathLayer()
        }
    }
    var textToAnimate = "Podlodka" {
        didSet {
            setupPathLayer()
        }
    }
    var delegate: TextAnimatorDelegate?
    var withBackground: Bool = false {
        didSet {
            setupPathLayer()
        }
    }
    var withStroke: Bool = true {
        didSet {
            setupPathLayer()
        }
    }
    
    // MARK: - Private properties
    
    private var animationLayer = CALayer()
    private var backgroundLayer: CAShapeLayer?
    private var borderLayer: CAShapeLayer?
    private var textLayer: CAShapeLayer?
    private var referenceView : UIView
    private var textColor = UIColor.purple.cgColor
    private var backgroundColor = UIColor.systemBlue.cgColor
    private var ctFrame: CTFrame?
    private var framesetter: CTFramesetter?
    private var strokeWidth: CGFloat {
        0.4 * fontSize
    }
    
    // MARK: - Init
    
    init(referenceView: UIView) {
        self.referenceView = referenceView
        super.init()
        defaultConfiguration()
    }
    
    deinit {
        clearLayer()
    }
    
    // MARK: - Private methods
    
    private func defaultConfiguration() {
        animationLayer = CALayer()
        animationLayer.frame = referenceView.bounds
        referenceView.layer.addSublayer(animationLayer)
        setupPathLayer()
    }
    
    // MARK: Animations
    
    private func clearLayer() {
        borderLayer?.removeFromSuperlayer()
        borderLayer = nil
        
        textLayer?.removeFromSuperlayer()
        textLayer = nil
        
        backgroundLayer?.removeFromSuperlayer()
        backgroundLayer = nil
    }
    
    private func setupPathLayer() {
        clearLayer()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributedString = NSAttributedString(
            string: self.textToAnimate,
            attributes: [
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle,
                .font: UIFont(name: self.fontName, size: self.fontSize)
            ]
        )
        
        framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)
        let rectPath = CGPath(rect: referenceView.bounds, transform: nil)
        ctFrame = CTFramesetterCreateFrame(framesetter!, CFRangeMake(0, attributedString.length), rectPath, nil)
        
        // Вытащим линии из нашего CTFrame.
        guard let lines = CTFrameGetLines(ctFrame!) as? [CTLine] else {
            return
        }
        
        // Это будет суммарная кривая нашего текста.
        let letters = CGMutablePath()
        let backgrounds = CGMutablePath()
        
        // Итерируемся построчно
        for (index, line) in lines.enumerated() {
            // Получаем массив с CTRun.
            // Каждый CTRun - непрерывный список символов с одинаковыми аттрибутами.
            let runArray = CTLineGetGlyphRuns(line)
            
            // Итерируемся по CTRun.
            for runIndex in 0 ..< CFArrayGetCount(runArray) {
                // Достаем CTRun из C массива.
                let run: CTRun = unsafeBitCast(CFArrayGetValueAtIndex(runArray, runIndex), to: CTRun.self)
                // Получаем список аттрибутов.
                let dict: NSDictionary = CTRunGetAttributes(run) as NSDictionary
                // Вытаскиваем шрифт из списка аттрибутов.
                let runFont = dict[kCTFontAttributeName as String] as! CTFont
                
                // Иттерируемся по символам.
                for runGlyphIndex in 0..<CTRunGetGlyphCount(run) {
                    let thisGlyphRange = CFRangeMake(runGlyphIndex, 1)
                    var glyph = CGGlyph()
                    var position = CGPointZero
                    // Получаем глифы.
                    CTRunGetGlyphs(run, thisGlyphRange, &glyph)
                    // Получаем origin для каждого глифа.
                    CTRunGetPositions(run, thisGlyphRange, &position)
                    
                    // Создаем CGPath для глифа с помощью CTFont.
                    guard let letter = CTFontCreatePathForGlyph(runFont, glyph, nil) else { continue }
                    // Создаем аффинное преобразование для сдвига глифа на его позицию.
                    let t = CGAffineTransformMakeTranslation(position.x, position.y)
                    // Добавляем полученный CGPath в общую кривую для всего текста.
                    letters.addPath(letter, transform: t)
                }
            }
            
            // Посчитаем размер рамки вокруг строки текста.
            let backgroundRect = background(for: line, at: index)
            // Расширим на ширину обводки.
                .insetBy(dx: -strokeWidth, dy: -strokeWidth)
            
            // Создадим CGPath с закругленными углами на основе вычисленного размера.
            let corner = 0.2 * fontSize
            let backgroundPath = CGPath(
                roundedRect: backgroundRect,
                cornerWidth: corner,
                cornerHeight: corner,
                transform: nil
            )
            // Добавляем полученный CGPath в общую кривую для всего фона.
            backgrounds.addPath(backgroundPath)
        }
        
        // Создаем на основе кривой для фона UIBezierPath.
        let backgroundPath = UIBezierPath()
        backgroundPath.move(to: CGPointZero)
        backgroundPath.append(UIBezierPath(cgPath: backgrounds))
          
        // Создаем на основе кривой для символов UIBezierPath.
        let path = UIBezierPath()
        path.move(to: CGPointZero)
        path.append(UIBezierPath(cgPath: letters))
        
        // Создаем CAShapeLayer для обводки.
        let borderLayer = CAShapeLayer()
        borderLayer.frame = animationLayer.bounds
        borderLayer.bounds = letters.boundingBox
        borderLayer.isGeometryFlipped = true
        borderLayer.path = path.cgPath
        borderLayer.strokeColor = UIColor.black.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = strokeWidth
        borderLayer.lineJoin = .round
        
        // Создаем CAShapeLayer для текста.
        let textLayer = CAShapeLayer()
        textLayer.frame = animationLayer.bounds
        textLayer.bounds = letters.boundingBox
        textLayer.isGeometryFlipped = true
        textLayer.path = path.cgPath
        textLayer.fillColor = textColor
        
        // Создаем CAShapeLayer для фона.
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.frame = animationLayer.bounds
        backgroundLayer.bounds = backgrounds.boundingBox
        backgroundLayer.path = backgroundPath.cgPath
        backgroundLayer.fillColor = backgroundColor
        backgroundLayer.isGeometryFlipped = true
        
        if withBackground {
            self.animationLayer.addSublayer(backgroundLayer)
        }
        
        if withStroke {
            self.animationLayer.addSublayer(borderLayer)
        }
        
        self.animationLayer.addSublayer(textLayer)
        self.borderLayer = borderLayer
        self.textLayer = textLayer
        self.backgroundLayer = backgroundLayer
    }
    
    private func background(for line: CTLine, at index: Int) -> CGRect {
        guard let ctFrame else { return .zero }
        
        // Сюда мы запишем origin для нашей линии.
        let lineOrigin = UnsafeMutablePointer<CGPoint>.allocate(capacity: 1)
        defer {
            // Нужно обязательно не забыть освободить память.
            lineOrigin.deallocate()
        }
        
        // Достаем origin.
        CTFrameGetLineOrigins(ctFrame, CFRange(location: index, length: 1), lineOrigin)
        
        // Достаем границы bounds для нашей линии.
        let lineBounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        
        // Зная origin и bounds можно получить frame.
        // Не забываем первернуть y.
        let lineRect = CGRect(
            x: lineOrigin.pointee.x,
            y: referenceView.bounds.height - lineOrigin.pointee.y - lineBounds.origin.y - lineBounds.height,
            width: lineBounds.width,
            height: lineBounds.height
        )
        
        return lineRect
    }
    
    // MARK: - Internal methods
    
    func startAnimation() {
        let duration = 4.0
        borderLayer?.removeAllAnimations()
        textLayer?.removeAllAnimations()
        backgroundLayer?.removeAllAnimations()
        setupPathLayer()
        
        if withStroke {
            let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
            pathAnimation.duration = duration
            pathAnimation.fromValue = 0.0
            pathAnimation.toValue = 1.0
            pathAnimation.delegate = self
            borderLayer?.add(pathAnimation, forKey: "strokeEnd")
        }
        
        let coloringDuration = 2.0
        let colorAnimation = CAKeyframeAnimation(keyPath: "fillColor")
        colorAnimation.values = [UIColor.clear.cgColor, UIColor.clear.cgColor, textColor]
        
        if withStroke {
            colorAnimation.duration = duration + coloringDuration
            colorAnimation.keyTimes = [0, NSNumber(value: (duration/(duration + coloringDuration))), 1]
        } else {
            colorAnimation.duration = coloringDuration
        }
        
        textLayer?.add(colorAnimation, forKey: "fillColor")
        
        if withBackground {
            let backgroundAnimation = CABasicAnimation(keyPath: "fillColor")
            backgroundAnimation.fromValue = UIColor.clear.cgColor
            backgroundAnimation.toValue = backgroundColor
            backgroundAnimation.duration = colorAnimation.duration
            backgroundLayer?.add(backgroundAnimation, forKey: "fillColor")
        }
    }
    
    func stopAnimation() {
        borderLayer?.removeAllAnimations()
        textLayer?.removeAllAnimations()
    }
    
    func clearAnimationText() {
        clearLayer()
    }
    
    func prepareForAnimation() {
        borderLayer?.removeAllAnimations()
        textLayer?.removeAllAnimations()
        setupPathLayer()
        
        let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        pathAnimation.duration = 1.0
        pathAnimation.fromValue = 0.0
        pathAnimation.toValue = 1.0
        pathAnimation.delegate = self
        borderLayer?.add(pathAnimation, forKey: "strokeEnd")
        
        borderLayer?.speed = 0
    }
    
    func updatePathStrokeWithValue(value: Float) {
        borderLayer?.timeOffset = CFTimeInterval(value)
    }
}
    
extension TextAnimator: CAAnimationDelegate {
    func animationDidStart(_ anim: CAAnimation) {
        self.delegate?.textAnimator(self, animationDidStart: anim)
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.delegate?.textAnimator(self, animationDidStop: anim)
    }
}
