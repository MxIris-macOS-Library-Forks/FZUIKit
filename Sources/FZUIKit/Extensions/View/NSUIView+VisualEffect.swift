//
//  NSUIView+VisualEffect.swift
//
//
//  Created by Florian Zand on 03.02.23.
//

#if os(macOS) || os(iOS)
    #if os(macOS)
        import AppKit
    #elseif canImport(UIKit)
        import UIKit
    #endif

    public extension NSUIView {
        /**
         The visual effect of the view.

         The property adds a `VisualEffectView` as background to the view. The default value is `nil`.
         */
        var visualEffect: VisualEffectConfiguration? {
            get {
                #if os(macOS)
                if let view = self as? NSVisualEffectView {
                    return VisualEffectConfiguration(material: view.material, blendingMode: view.blendingMode, appearance: view.appearance, state: view.state, isEmphasized: view.isEmphasized, maskImage: view.maskImage)
                }
                #endif
               return visualEffectBackgroundView?.contentProperties
            }
            set {
                if let newValue = newValue {
                    #if os(macOS)
                    if let view = self as? NSVisualEffectView {
                        view.material = newValue.material
                        view.blendingMode = newValue.blendingMode
                        view.state = newValue.state
                        view.isEmphasized = newValue.isEmphasized
                        view.maskImage = newValue.maskImage
                        view.appearance = newValue.appearance
                    } else {
                        if visualEffectBackgroundView == nil {
                            visualEffectBackgroundView = TaggedVisualEffectView()
                        }
                        visualEffectBackgroundView?.contentProperties = newValue
                        if let appearance = newValue.appearance {
                            self.appearance = appearance
                        }
                    }
                    #else
                    if visualEffectBackgroundView == nil {
                        visualEffectBackgroundView = TaggedVisualEffectView()
                    }
                    visualEffectBackgroundView?.contentProperties = newValue
                    #endif
                } else {
                    visualEffectBackgroundView = nil
                }
            }
        }

        internal var visualEffectBackgroundView: TaggedVisualEffectView? {
            get { viewWithTag(TaggedVisualEffectView.Tag) as? TaggedVisualEffectView
            }
            set {
                if self.visualEffectBackgroundView != newValue {
                    self.visualEffectBackgroundView?.removeFromSuperview()
                }
                if let newValue = newValue {
                    insertSubview(newValue, at: 0)
                    newValue.constraint(to: self)
                }
            }
        }
    }

    #if os(macOS)
        extension NSView {
            class TaggedVisualEffectView: NSVisualEffectView {
                public static var Tag: Int {
                    3_443_024
                }

                override var tag: Int {
                    Self.Tag
                }

                public var contentProperties: VisualEffectConfiguration {
                    get {
                        VisualEffectConfiguration(material: material, blendingMode: blendingMode, appearance: appearance, state: state, isEmphasized: isEmphasized, maskImage: maskImage)
                    }
                    set {
                        material = newValue.material
                        blendingMode = newValue.blendingMode
                        state = newValue.state
                        isEmphasized = newValue.isEmphasized
                        maskImage = newValue.maskImage
                        appearance = newValue.appearance
                    }
                }
            }
        }

    #elseif canImport(UIKit)
        extension UIView {
            class TaggedVisualEffectView: UIVisualEffectView {
                public var contentProperties: VisualEffectConfiguration = .init() {
                    didSet { updateEffect() }
                }

                func updateEffect() {
                    #if os(iOS)
                    effect = contentProperties.effect
                    #elseif os(tvOS)
                        if let blur = contentProperties.blur {
                            effect = UIBlurEffect(style: blur)
                        } else {
                            effect = nil
                        }
                    #endif
                }

                public static var Tag: Int {
                    3_443_024
                }

                override var tag: Int {
                    get { Self.Tag }
                    set {}
                }
            }
        }
    #endif
#endif
