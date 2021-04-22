//
//  FaveIcon.swift
//  FaveButton
//
// Copyright © 2016 Jansel Valentin.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit


class FaveIcon: UIView
{
    var iconImage: UIImage!
    var selectedIconImage: UIImage?
    var iconColor: UIColor = .gray
    
    var iconLayer: CALayer!
    var maskedIconLayer: CAShapeLayer!
    
    var contentRegion: CGRect!
    var tweenValues: [CGFloat]?
    
    init(region: CGRect, icon: UIImage, selectedIcon: UIImage?, color: UIColor) {
        self.contentRegion = region
        
        self.iconImage = icon
        self.selectedIconImage = selectedIcon
        
        self.iconColor = color
        
        super.init(frame: CGRect.zero)
        
        applyInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// MARK: Create
extension FaveIcon
{
    class func createFaveIcon(_ onView: UIView, icon: UIImage, selectedIcon: UIImage?, color: UIColor) -> FaveIcon {
        let faveIcon = Init(FaveIcon(region:onView.bounds, icon: icon, selectedIcon: selectedIcon, color: color)) {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.backgroundColor = .clear
        }
        onView.addSubview(faveIcon)
        
        (faveIcon, onView) >>- [.centerX,.centerY]
        
        faveIcon >>- [.width,.height]
        
        return faveIcon
    }
    
    func applyInit() {
        let iconRegion  = contentRegion.size.scaleBy(0.7).rectCentered(at: contentRegion.center)
        let shapeOrigin = CGPoint(x: -contentRegion.center.x, y: -contentRegion.center.y)
        
        iconLayer = Init(CALayer()){
            $0.contents      = iconImage.cgImage
            $0.contentsScale = UIScreen.main.scale
            $0.bounds        = iconRegion
        }
        
        if selectedIconImage == nil {
            maskedIconLayer = Init(CAShapeLayer()) {
                $0.fillColor = iconColor.cgColor
                $0.path      = UIBezierPath(rect: CGRect(origin: shapeOrigin, size: contentRegion.size)).cgPath
                $0.mask      = iconLayer
            }
            layer.addSublayer(maskedIconLayer)
        }
        else {
            layer.addSublayer(iconLayer)
        }
    }
}


// MARK: Animation
extension FaveIcon
{
    func animateSelect(_ isSelected: Bool = false, fillColor: UIColor, duration: Double = 0.5, delay: Double = 0){
        let animate = duration > 0.0
        
        if nil == tweenValues && animate {
            tweenValues = generateTweenValues(from: 0, to: 1.0, duration: CGFloat(duration))
        }
        
        if selectedIconImage == nil {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
                maskedIconLayer.fillColor = fillColor.cgColor
            CATransaction.commit()
        }

        let selectedDelay = isSelected ? delay : 0
        
        if isSelected {
            self.alpha = 0
            UIView.animate(
                withDuration: 0,
                delay: selectedDelay,
                options: .curveLinear,
                animations: {
                    self.alpha = 1
                }, completion: { completed in
                    if completed, let image = self.selectedIconImage {
                        self.changeImageLayer(image: image)
                    }
                })
        }
        else if selectedIconImage != nil, let image = iconImage {
            changeImageLayer(image: image)
        }
        
        guard animate else {
            return
        }
        
        let scaleAnimation = Init(CAKeyframeAnimation(keyPath: "transform.scale")){
            $0.values    = tweenValues!
            $0.duration  = duration
            $0.beginTime = CACurrentMediaTime()+selectedDelay
        }
        iconLayer.add(scaleAnimation, forKey: nil)
    }
    
    private func changeImageLayer(image: UIImage) {
        let oldIconMask = iconLayer
        
        let maskRegion = contentRegion.size.scaleBy(0.7).rectCentered(at: contentRegion.center)
        let newIconMask = Init(CALayer()) {
            $0.contents      = image.cgImage
            $0.contentsScale = UIScreen.main.scale
            $0.bounds        = maskRegion
        }
        layer.addSublayer(newIconMask)
        
        oldIconMask?.removeFromSuperlayer()
        iconLayer = newIconMask
    }
    
    private func generateTweenValues(from: CGFloat, to: CGFloat, duration: CGFloat) -> [CGFloat] {
        var values         = [CGFloat]()
        let fps            = CGFloat(60.0)
        let tpf            = duration/fps
        let c              = to-from
        let d              = duration
        var t              = CGFloat(0.0)
        let tweenFunction  = Elastic.ExtendedEaseOut
        
        while(t < d) {
            let scale = tweenFunction(t, from, c, d, c+0.001, 0.39988)  // p=oscillations, c=amplitude(velocity)
            values.append(scale)
            t += tpf
        }
        return values
    }
}
