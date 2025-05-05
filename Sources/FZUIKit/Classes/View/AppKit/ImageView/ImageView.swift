//
//  ImageView.swift
//
//
//  Created by Florian Zand on 13.03.24.
//

#if os(macOS)
import AppKit
import FZSwiftUtils

/// An enhanced image view.
@IBDesignable
open class ImageView: NSControl {
    let containerView = ContainerView()
    let imageView = NSImageView()
    var timer: DisplayLinkTimer? = nil
    var currentRepeatCount = 0
    var ignoreTransition = false
    var trackingArea: TrackingArea?
    var currentImageIndex = 0 {
        didSet { updateDisplayingImage() }
    }
    
    // MARK: - Specifying the image
    
    /// The image displayed in the image view.
   @IBInspectable open var image: NSImage? {
       get { images.count == 1 ? images.first : animatedImage?.image }
        set {
            guard newValue != image else { return }
            if let newImage = newValue {
                if let animated = AnimatedImage(newImage) {
                    images = []
                    animatedImage = animated
                } else {
                    images = [newImage]
                }
            } else {
                images = []
            }
        }
    }
    
    open override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return false
    }
        
    /// Sets the image displayed in the image view.
    @discardableResult
    open func image(_ image: NSImage?) -> Self {
        self.image = image
        return self
    }

    /// The images displayed by the image view.
    open var images: [NSImage] = [] {
        didSet {
            animatedImage = nil
            croppedImages = []
            nonAlphaRects.removeAll()
            imagesUpdated()
        }
    }
    
    var croppedImages: [NSImage] = []
    var nonAlphaRects: SynchronizedArray<CGRect> = []
    
    /// A Boolean value that indicates whether the images should be cropped to  non their non alpha area.
    open var cropImagesToNonTransparent: Bool = false {
        didSet {
            guard oldValue != cropImagesToNonTransparent else { return }
            updateDisplayingImage()
        }
    }
    
    /// Sets the Boolean value that indicates whether the images should be cropped to  non their non alpha area.
    @discardableResult
    open func cropImagesToNonTransparent(_ crop: Bool) -> Self {
        cropImagesToNonTransparent = crop
        return self
    }
    var croppedImageRect: CGRect? = nil
    
    /// Sets the images displayed by the image view.
    @discardableResult
    open func images(_ images: [NSImage]) -> Self {
        self.images = images
        return self
    }
    
    var animatedImage: AnimatedImage? = nil {
        didSet {
            if let animatedImage = animatedImage {
                croppedImages = []
                nonAlphaRects.removeAll()
                animationDuration = animatedImage.duration
                animationRepeatCount = animatedImage.loopCount
                imagesUpdated()
            }
        }
    }
    
    func imagesUpdated() {
        
        containerView.isHidden = imagesCount == 0
        overlayContentView.isHidden = containerView.isHidden
        stopAnimating()
        currentImageIndex = 0
        if isAnimatable, animationPlayback == .automatic {
            startAnimating()
        }
    }
    
    /// The currently displayed image.
    open var displayingImage: NSImage? {
        image ?? animatedImage?[currentImageIndex] ?? images[safe: currentImageIndex]
    }
    
    /// The symbol configuration of the image.
    @available(macOS 11.0, *)
    open var symbolConfiguration: NSImage.SymbolConfiguration? {
        get { imageView.symbolConfiguration }
        set { imageView.symbolConfiguration = newValue }
    }
    
    /// The symbol configuration of the image.
    @available(macOS 13.0, *)
    open var imageSymbolConfiguration: ImageSymbolConfiguration? {
        get { imageView.imageSymbolConfiguration }
        set { imageView.imageSymbolConfiguration = newValue }
    }
    
    /// Sets the symbol configuration of the image.
    @discardableResult
    @available(macOS 11.0, *)
    open func symbolConfiguration(_ symbolConfiguration: NSImage.SymbolConfiguration?) -> Self {
        self.symbolConfiguration = symbolConfiguration
        return self
    }
    
    /// Sets the symbol configuration of the image.
    @discardableResult
    @available(macOS 13.0, *)
    open func symbolConfiguration(_ symbolConfiguration: ImageSymbolConfiguration?) -> Self {
        imageSymbolConfiguration = symbolConfiguration
        return self
    }
        
    /**
     A view for hosting layered content on top of the image view.
     
     Use this view to host content that you want layered on top of the image view. This view is managed by the image view itself and is automatically sized to fill the image view’s frame rectangle. Add your subviews and use layout constraints to position them within the view.
     
     The view in this property clips its subviews to its bounds rectangle by default, but you can change that behavior using the `clipsToBounds` property.
     */
    public let overlayContentView = NSView()
    
    /**
     The current size and position of the image that displays within the image view’s bounds.
     
     Use this property to determine the display dimensions of the image within the image view’s bounds. The size and position of this rectangle depends on the image scaling and alignment.
     */
    @objc dynamic public var imageBounds: CGRect {
        overlayContentView.frame
    }
                
    // MARK: - Specifying the visual characteristics
    
    /// The image scaling.
    open var imageScaling: ImageScaling = .scaleToFit {
        didSet {
            guard oldValue != imageScaling else { return }
            imageView.imageScaling = imageScaling.nsImageScaling
            layout()
        }
    }
    
    /// Sets the image scaling.
    @discardableResult
    open func imageScaling(_ imageScaling: ImageScaling) -> Self {
        self.imageScaling = imageScaling
        return self
    }
    
    /// Constants that specify the image scaling behavior.
    public enum ImageScaling: Int {
        /// The image is resized to fit the bounds rectangle, preserving the aspect of the image. If the image does not completely fill the bounds rectangle, the image is centered in the partial axis.
        case scaleToFit
        /// The image is resized to completely fill the bounds rectangle, while still preserving the aspect of the image.
        case scaleToFill
        /// The image is resized to fit the entire bounds rectangle.
        case resize
        /// The image isn't resized.
        case none
        
        var nsImageScaling: NSImageScaling {
            switch self {
            case .resize: return .scaleAxesIndependently
            case .none: return .scaleNone
            default: return .scaleProportionallyUpOrDown
            }
        }
    }
    
    /// The image alignment inside the image view.
    open var imageAlignment: NSImageAlignment = .alignCenter {
        didSet {
            guard oldValue != imageAlignment else { return }
            imageView.imageAlignment = imageAlignment
            layout()
        }
    }
    
    /// Sets the image alignment inside the image view.
    @discardableResult
    open func imageAlignment(_ alignment: NSImageAlignment) -> Self {
        self.imageAlignment = alignment
        return self
    }
    
    /// The corner radius of the image.
    open var imageCornerRadius: CGFloat {
        get { containerView.cornerRadius }
        set { containerView.cornerRadius = newValue }
    }
    
    /// Sets the corner radius of the image.
    @discardableResult
    open func imageCornerRadius(_ cornerRadius: CGFloat) -> Self {
        self.imageCornerRadius = cornerRadius
        return self
    }
    
    /// The corner curve of the image.
    open var imageCornerCurve: CALayerCornerCurve {
        get { containerView.cornerCurve }
        set { containerView.cornerCurve = newValue }
    }
    
    /// Sets the corner curve of the image.
    @discardableResult
    open func imageCornerCurve(_ cornerCurve: CALayerCornerCurve) -> Self {
        self.imageCornerCurve = cornerCurve
        return self
    }
    
    /// The rounded corners of the image.
    open var imageRoundedCorners: CACornerMask {
        get { containerView.roundedCorners }
        set { containerView.roundedCorners = newValue }
    }
    
    /// Sets the rounded corners of the image.
    @discardableResult
    open func imageRoundedCorners(_ roundedCorners: CACornerMask) -> Self {
        self.imageRoundedCorners = roundedCorners
        return self
    }
    
    /// The background color of the image.
    open var imageBackgroundColor: NSColor? {
        get { containerView.backgroundColor }
        set { containerView.backgroundColor = newValue }
    }
    
    /// Sets the background color of the image.
    @discardableResult
    open func imageBackgroundColor(_ backgroundColor: NSColor?) -> Self {
        self.imageBackgroundColor = backgroundColor
        return self
    }
    
    /// The outer shadow of the image.
    open var imageShadow: ShadowConfiguration {
        get { containerView.outerShadow }
        set { containerView.outerShadow = newValue }
    }
    
    /// Sets the outer shadow of the image.
    @discardableResult
    open func imageShadow(_ shadow: ShadowConfiguration) -> Self {
        self.imageShadow = shadow
        return self
    }
    
    /// The inner shadow of the image.
    open var imageInnerShadow: ShadowConfiguration {
        get { containerView.innerShadow }
        set { containerView.innerShadow = newValue }
    }
    
    /// Sets the inner shadow of the image.
    @discardableResult
    open func imageInnerShadow(_ shadow: ShadowConfiguration) -> Self {
        self.imageInnerShadow = shadow
        return self
    }
    
    /// The border of the image.
    open var imageBorder: BorderConfiguration {
        get { containerView.border }
        set { containerView.border = newValue }
    }
    
    /// Sets the border of the image.
    @discardableResult
    open func imageBorder(_ border: BorderConfiguration) -> Self {
        self.imageBorder = border
        return self
    }
        
    /// The image tint color for template and symbol images.
    @IBInspectable open var tintColor: NSColor? {
        didSet { updateTintColor() }
    }
    
    /// Sets the image tint color for template and symbol images.
    @discardableResult
    open func tintColor(_ tintColor: NSColor?) -> Self {
        self.tintColor = tintColor
        return self
    }
    
    var tintColorTransformer: ColorTransformer? = nil {
        didSet { updateTintColor() }
    }
    
    var currentBackgroundStyle: NSView.BackgroundStyle = .normal

    open override func setBackgroundStyle(_ backgroundStyle: NSView.BackgroundStyle) {
        guard backgroundStyle != currentBackgroundStyle else { return }
        currentBackgroundStyle = backgroundStyle
        tintColorTransformer = backgroundStyle == .emphasized ? .color(.white) : nil
        super.setBackgroundStyle(backgroundStyle)
    }
    
    func updateTintColor() {
        if let tintColor = tintColor {
            imageView.contentTintColor = tintColorTransformer?(tintColor) ?? tintColor
        } else {
            imageView.contentTintColor = nil
        }
    }
    
    // MARK: - Configurating animations
    
    /// Starts animating the images.
    open func startAnimating() {
        guard isAnimatable, !isAnimating else { return }
        currentRepeatCount = 0
        
        timer = DisplayLinkTimer(timeInterval: .seconds(timerInterval), repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.ignoreTransition = true
            self.setImageFrame(to: .nextLooped)
            self.ignoreTransition = false
            
            if self.animationRepeatCount != 0, self.currentImageIndex == 0 {
                self.currentRepeatCount += 1
            }
            if self.animationRepeatCount != 0, self.currentRepeatCount >= self.animationRepeatCount {
                self.timer?.stop()
                self.timer = nil
                self.currentRepeatCount = 0
            }
        }
    }

    /// Pauses animating the images.
    open func pauseAnimating() {
        timer?.stop()
        timer = nil
    }

    /// Stops animating the images and displays the first image.
    open func stopAnimating() {
        pauseAnimating()
        setImageFrame(to: .first)
    }
    
    enum AnimationPlaybackState: Int {
        case isAnimating
        case isPaused
        case isStopped
    }
    
    var animationPlaybackState: AnimationPlaybackState {
        get { isAnimating ? .isAnimating : currentImageIndex > 0 ? .isPaused : .isStopped }
        set {
            switch newValue {
            case .isAnimating: startAnimating()
            case .isPaused: pauseAnimating()
            case .isStopped: stopAnimating()
            }
        }
    }

    /// A Boolean value that indicates whether the animation is running.
    open var isAnimating: Bool {
        timer != nil
    }

    /// Toggles the animation.
    open func toggleAnimating() {
        if isAnimatable {
            if isAnimating {
                pauseAnimating()
            } else {
                startAnimating()
            }
        }
    }
    
    var timerInterval: TimeInterval {
        if animationDuration == 0.0 {
            return ImageSource.defaultFrameDuration / Double(imagesCount)
        } else {
            return animationDuration / Double(imagesCount)
        }
    }

    var isAnimatable: Bool {
        imagesCount > 1
    }

    /**
     The amount of time it takes to go through one cycle of an animated image.

     The time duration is measured in seconds. The default value of this property is `0.0`, which causes the image view to use a duration equal to the number of images multiplied by 1/30th of a second. Thus, if you had 30 images, the duration would be 1 second.
     */
    open var animationDuration: TimeInterval = 0.0 {
        didSet {
            timer?.timeInterval.seconds = timerInterval
        }
    }
    
    /// Sets the amount of time it takes to go through one cycle of an animated image.
    @discardableResult
    open func animationDuration(_ duration: TimeInterval) -> Self {
        self.animationDuration = duration
        return self
    }
    
    /**
     Specifies the number of times to repeat the animation.

     The default value is `0`, which specifies to repeat the animation indefinitely.
     */
    open var animationRepeatCount: Int = 0
    
    /// Sets the number of times to repeat the animation.
    @discardableResult
    open func animationRepeatCount(_ repeatCount: Int) -> Self {
        self.animationRepeatCount = repeatCount
        return self
    }

    /// The playback behavior for animated images.
    open var animationPlayback: AnimationPlaybackOption = .automatic {
        didSet {
            guard oldValue != animationPlayback else { return }
            if animationPlayback == .automatic {
                startAnimating()
            } else {
                stopAnimating()
            }
            if animationPlayback == .onMouseHover {
                trackingArea = TrackingArea(for: self, options: [.mouseEnteredAndExited, .activeAlways])
                updateTrackingAreas()
            } else {
                trackingArea = nil
            }
        }
    }
    
    /// Sets the playback behavior for animated images.
    @discardableResult
    open func animationPlayback(_ animationPlayback: AnimationPlaybackOption) -> Self {
        self.animationPlayback = animationPlayback
        return self
    }
    
    /// Constants that specify the playback behavior for animated images.
    public enum AnimationPlaybackOption: Int, Hashable {
        /// Images don't start animate automatically.
        case none
        /// Images start animating automatically.
        case automatic
        /// Images start animating when the mouse enteres the view and stop animating when the mouse exists the view.
        case onMouseHover
        /// A mouse down click toggles animating the images.
        case onMouseClick
    }
    
    // MARK: - Configurating transitions
    
    /// The transition animation when changing the displayed image.
    open var transitionAnimation: TransitionAnimation = .none
    
    /// Sets the transition animation when changing the displayed image.
    @discardableResult
    open func transitionAnimation(_ transition: TransitionAnimation) -> Self {
        self.transitionAnimation = transition
        return self
    }
    
    /// The duration of the transition animation.
    open var transitionDuration: TimeInterval = 0.2
    
    /// Sets the duration of the transition animation.
    @discardableResult
    open func transitionDuration(_ duration: TimeInterval) -> Self {
        self.transitionDuration = duration
        return self
    }
    
    /// Constants that specify the transition animation when changing between displayed images.
    public enum TransitionAnimation: Hashable, CustomStringConvertible {
        /// No transition animation.
        case none
        /// The new image fades in.
        case fade
        /// The new image slides into place over any existing image from the specified direction.
        case moveIn(_ direction: Direction = .fromLeft)
        /// The new image pushes any existing image as it slides into place from the specified direction.
        case push(_ direction: Direction = .fromLeft)
        /// The new image is revealed gradually in the specified direction.
        case reveal(_ direction: Direction = .fromLeft)
        
        /// The direction of the transition.
        public enum Direction: String, Hashable {
            /// From left.
            case fromLeft
            /// From right.
            case fromRight
            /// From bottom.
            case fromBottom
            /// From top.
            case fromTop
            var subtype: CATransitionSubtype {
                CATransitionSubtype(rawValue: rawValue)
            }
        }
        
        public var description: String {
            switch self {
            case .none: return "TransitionAnimation.none"
            case .fade: return "TransitionAnimation.fade"
            case .moveIn(let direction): return "TransitionAnimation.moveIn(\(direction.rawValue))"
            case .push(let direction): return "TransitionAnimation.push(\(direction.rawValue))"
            case .reveal(let direction): return "TransitionAnimation.reveal(\(direction.rawValue))"
            }
        }
        
        var type: CATransitionType? {
            switch self {
            case .fade: return .fade
            case .moveIn: return .moveIn
            case .push: return .push
            case .reveal: return .reveal
            case .none: return nil
            }
        }
        
        var subtype: CATransitionSubtype? {
            switch self {
            case .moveIn(let direction), .push(let direction), .reveal(let direction):
                return direction.subtype
            default: return nil
            }
        }
        
        func transition(_ duration: TimeInterval) -> CATransition? {
            guard let type = type else { return nil }
            return CATransition(type, subtype: subtype, duration: duration)
        }
    }
    
    // MARK: - Specifying the dynamic range
    
    /// The dynamic range of the image.
    @available(macOS 14.0, *)
    open var imageDynamicRange: NSImage.DynamicRange {
        get { imageView.imageDynamicRange }
    }
    
    /// The preferred dynamic image range.
    @available(macOS 14.0, *)
    open var preferredImageDynamicRange: NSImage.DynamicRange {
        get { imageView.preferredImageDynamicRange }
        set { imageView.preferredImageDynamicRange = newValue }
    }
    
    /// Sets the preferred dynamic image range.
    @discardableResult
    @available(macOS 14.0, *)
    open func preferredImageDynamicRange(_ dynamicRange: NSImage.DynamicRange) -> Self {
        self.preferredImageDynamicRange = dynamicRange
        return self
    }
    
    /// The default preferred dynamic image range.
    @available(macOS 14.0, *)
    open class var defaultPreferredImageDynamicRange: NSImage.DynamicRange {
        get { NSImageView.defaultPreferredImageDynamicRange }
        set { NSImageView.defaultPreferredImageDynamicRange = newValue }
    }
    
    // MARK: - Responding to user events
    
    /// A value that indicates whether the image view can be selected.
    open var isSelectable: SelectionOption = false {
        didSet {
            guard isSelectable != oldValue else { return }
            if isSelectable == .off {
                resignFirstResponding()
            }
        }
    }
    
    /// Sets the value that indicates whether the image view can be selected.
    @discardableResult
    open func isSelectable(_ isSelectable: SelectionOption) -> Self {
        self.isSelectable = isSelectable
        return self
    }
    
    /// Constant that indicates whether the user can select the image view.
    public enum SelectionOption: Int, ExpressibleByBooleanLiteral {
        /// The user can select the image view by clickling the image.
        case byImage
        /// The user can select the image view by clickling the image view.
        case byView
        /// The user can't select the image.
        case off
        
        public init(booleanLiteral value: Bool) {
            self = value ? .byView : .off
        }
    }
    
    /// A Boolean value indicating whether the image view is selected.
    @objc dynamic open internal(set) var isSelected: Bool = false

    /**
     A Boolean value indicating whether the user can drag a new image into the image view.
     
     When the value of this property is `true`, the user can set the displayed image by dragging an image onto the image view. The action is called.
     */
    open var isEditable: Bool {
        get { imageView.isEditable }
        set { imageView.isEditable = newValue }
    }
    
    /// Sets the Boolean value indicating whether the user can drag a new image into the image view.
    @discardableResult
    open func isEditable(_ isEditable: Bool) -> Self {
        self.isEditable = isEditable
        return self
    }
    
    /**
     A Boolean value indicating whether the image view lets the user cut, copy, and paste the image contents.

     When the value of this property is `true`, the user can cut, copy, or paste the image in the image view.
     */
    open var allowsCutCopyPaste: Bool {
        get { imageView.allowsCutCopyPaste }
        set { imageView.allowsCutCopyPaste = newValue }
    }
    
    /// Sets the Boolean value indicating whether the image view lets the user cut, copy, and paste the image contents.
    @discardableResult
    open func allowsCutCopyPaste(_ allowsCutCopyPaste: Bool) -> Self {
        self.allowsCutCopyPaste = allowsCutCopyPaste
        return self
    }
    
    // MARK: - Configuring symbol effects

        
    /**
     Adds an indefinite symbol effect to the image view with the specified options and animation.
     
     - Parameters:
        - effect: The symbol effect to add.
        - options: The options for the symbol effect.
        - animated: A Boolean value that indicates whether to animate the addition of a scale, appear, or disappear effect.
    */
    @MainActor
    @available(macOS 14.0, *)
    open func addSymbolEffect(
        _ effect: some IndefiniteSymbolEffect & SymbolEffect,
        options: SymbolEffectOptions = .default,
        animated: Bool = true) {
        imageView.addSymbolEffect(effect, options: options, animated: animated)
    }
    
    /**
     Adds a discrete symbol effect to the image view with the specified options and animation.
     
     - Parameters:
        - effect: The symbol effect to add.
        - options: The options for the symbol effect.
        - animated: A Boolean value that indicates whether to animate the addition of a scale, appear, or disappear effect.
    */
    @MainActor
    @available(macOS 14.0, *)
    open func addSymbolEffect(
        _ effect: some DiscreteSymbolEffect & SymbolEffect,
        options: SymbolEffectOptions = .default,
        animated: Bool = true) {
        imageView.addSymbolEffect(effect, options: options, animated: animated)
    }
    
    /**
     Adds a discrete, indefinite symbol effect to the image view with the specified options and animation.
     
     - Parameters:
        - effect: The symbol effect to add.
        - options: The options for the symbol effect.
        - animated: A Boolean value that indicates whether to animate the addition of a scale, appear, or disappear effect.
     */
    @MainActor
    @available(macOS 14.0, *)
    open func addSymbolEffect(
        _ effect: some DiscreteSymbolEffect & IndefiniteSymbolEffect & SymbolEffect,
        options: SymbolEffectOptions = .default,
        animated: Bool = true) {
        imageView.addSymbolEffect(effect, options: options, animated: animated)
    }
    
    /**
     Sets a symbol image using the specified content-transition effect and options.
     
     - Parameters:
        - image: The symbol image to set.
        - contentTransition: The content transition to use when setting the symbol image.
        - options: The options to use when setting the symbol image.
     */
    @MainActor
    @available(macOS 14.0, *)
    open func setSymbolImage(
        _ image: NSImage,
        contentTransition: some ContentTransitionSymbolEffect & SymbolEffect,
        options: SymbolEffectOptions = .default) {
            imageView.setSymbolImage(image, contentTransition: contentTransition, options: options)
    }
    
    /**
     Removes the symbol effect that matches the specified indefinite effect type, using the specified options and animation setting.
     
     - Parameters:
        - effect: The symbol effect to match for removal.
        - options: The options to use when removing the symbol effect.
        - animated: A Boolean value that indicates whether to animate the removal of a scale, appear, or disappear effect.
     */
    @MainActor
    @available(macOS 14.0, *)
    open func removeSymbolEffect(
        ofType effect: some IndefiniteSymbolEffect & SymbolEffect,
        options: SymbolEffectOptions = .default,
        animated: Bool = true) {
            imageView.removeSymbolEffect(ofType: effect, options: options, animated: animated)
    }
    
    /**
     Removes the symbol effect that matches the specified discrete, indefinite effect type, using the specified options and animation setting.
     
     - Parameters:
        - effect: The symbol effect to match for removal.
        - options: The options to use when removing the symbol effect.
        - animated: A Boolean value that indicates whether to animate the removal of a scale, appear, or disappear effect.
     */
    @MainActor
    @available(macOS 14.0, *)
    open func removeSymbolEffect(
        ofType effect: some DiscreteSymbolEffect & IndefiniteSymbolEffect & SymbolEffect,
        options: SymbolEffectOptions = .default,
        animated: Bool = true) {
            imageView.removeSymbolEffect(ofType: effect, options: options, animated: animated)
    }
    
    /**
     Removes the symbol effect that matches the specified discrete effect type, using the specified options and animation setting.
     
     - Parameters:
        - effect: The symbol effect to match for removal.
        - options: The options to use when removing the symbol effect.
        - animated: A Boolean value that indicates whether to animate the removal of a scale, appear, or disappear effect.
     */
    @MainActor
    @available(macOS 14.0, *)
    open func removeSymbolEffect(
        ofType effect: some DiscreteSymbolEffect & SymbolEffect,
        options: SymbolEffectOptions = .default,
        animated: Bool = true) {
            imageView.removeSymbolEffect(ofType: effect, options: options, animated: animated)
    }
    
    /**
     Removes all symbol effects from the image view, using the specified options and animation setting.
     
     - Parameters:
        - options: The options to use when removing the symbol effects.
        - animated: A Boolean value that indicates whether to animate the removal of a scale, appear, or disappear effects.
     */
    @MainActor
    @available(macOS 14.0, *)
    open func removeAllSymbolEffects(
        options: SymbolEffectOptions = .default,
        animated: Bool = true) {
            imageView.removeAllSymbolEffects(options: options, animated: animated)
    }
    
    /**
     Returns an image view initialized with the specified image.
     
     - Parameter image: The initial image to display in the image view. You may specify an image object that contains an animated sequence of images.
     
     - Returns: An initialized image view object.
     */
    public init(image: NSImage?) {
        super.init(frame: .zero)
        sharedInit()
        imageView.image = image
    }
    
    /**
     Returns an image view initialized with the specified symbol image.
     
     - Parameter symbolName: The name of the symbol image.
     
     - Returns: An initialized image view object.
     */
    @available(macOS 11.0, *)
    public init(symbolName: String) {
        super.init(frame: .zero)
        sharedInit()
        imageView.image = NSImage(systemSymbolName: symbolName)
    }
    
    public init() {
        super.init(frame: .zero)
        sharedInit()
    }
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        sharedInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    open override var fittingSize: NSSize {
        imageView.fittingSize
    }
    
    open override var intrinsicContentSize: NSSize {
        imageView.intrinsicContentSize
    }

    private func sharedInit() {
        imageView.frame = bounds
        imageView.animates = false
        imageView.imageScaling = imageScaling.nsImageScaling
        imageView.imageAlignment = imageAlignment
        
        containerView.frame = bounds
        containerView.clipsToBounds = true
        addSubview(containerView)
        containerView.addSubview(imageView)
        
        overlayContentView.frame = bounds
        containerView.addSubview(overlayContentView)
        cell = imageView.cell        
    }
    
    open override func layout() {
        super.layout()
        guard displayingImage != nil else { return }
        let containerViewFrame = containerView.frame
        if imageScaling == .scaleToFill, let imageSize = displayingImage?.size {
            imageView.frame.size = imageSize.scaled(toFill: bounds.size)
            switch imageAlignment {
            case .alignTopLeft:
                imageView.frame.topLeft = bounds.topLeft
            case .alignTop:
                imageView.frame.topCenter = bounds.topCenter
            case .alignTopRight:
                imageView.frame.topRight = bounds.topRight
            case .alignBottomLeft:
                imageView.frame.bottomLeft = bounds.bottomLeft
            case .alignBottom:
                imageView.frame.bottomCenter = bounds.bottomCenter
            case .alignBottomRight:
                imageView.frame.bottomRight = bounds.bottomRight
            case .alignLeft:
                imageView.frame.centerLeft = bounds.centerLeft
            case .alignRight:
                imageView.frame.centerRight = bounds.centerRight
            default:
                imageView.center = bounds.center
            }
            containerView.frame.origin.x = imageView.frame.x.clamped(min: 0)
            containerView.frame.origin.y = imageView.frame.y.clamped(min: 0)
            containerView.frame.size.width = imageView.frame.size.width.clamped(to: 0...bounds.width)
            containerView.frame.size.height = imageView.frame.size.height.clamped(to: 0...bounds.height)
        } else {
            imageView.frame = bounds
            containerView.frame = imageView.imageBounds
            imageView.frame = containerView.bounds
            /*
            if cropImagesToNonTransparent, imageScaling == .scaleToFit, let imageSize = displayingImage?.size, let alphaRect = displayingImage?.nonAlphaRect() {
                let xFactor = (imageSize.width / alphaRect.width)
                let yFactor = (imageSize.height / alphaRect.height)
               imageView.frame.size = CGSize(bounds.width * xFactor, bounds.height * yFactor )
               imageView.center = center
             //   containerView.frame = imageView.imageBounds
               // imageView.frame = containerView.bounds
            }
             */
        }
        if containerViewFrame != containerView.frame {
            willChangeValue(for: \.imageBounds)
            overlayContentView.frame = containerView.bounds
            didChangeValue(for: \.imageBounds)
        }
    }
    
    open override class var cellClass: AnyClass? {
        get { NSImageView.cellClass }
        set { }
    }
    
    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingArea?.update()
    }
    
    open override func mouseEntered(with event: NSEvent) {
        if animationPlayback == .onMouseHover {
            startAnimating()
        }
    }

    open override func mouseExited(with event: NSEvent) {
        if animationPlayback == .onMouseHover {
            stopAnimating()
        }
    }
    
    open override func becomeFirstResponder() -> Bool {
        if acceptsFirstResponder, !isSelected {
            isSelected = true
        }
        return acceptsFirstResponder
    }
    
    open override func resignFirstResponder() -> Bool {
        if isSelected {
            isSelected = false
        }
        return true
    }
    
    /*
    open override func mouseDown(with event: NSEvent) {
        if isSelectable == .byView, !isFirstResponder {
            makeFirstResponder()
            performAction()
        } else if isSelectable == .byImage, overlayContentView.frame.contains(event.location(in: self)), !isFirstResponder {
            makeFirstResponder()
            performAction()
        }
        if animationPlayback == .onMouseClick, overlayContentView.frame.contains(event.location(in: self)) {
            toggleAnimating()
        }
        super.mouseDown(with: event)
    }
     */
    
    func updateDisplayingImage() {
        if !ignoreTransition, let transition = transitionAnimation.transition(transitionDuration) {
            self.transition(transition)
        }
        let oldImageSize = imageView.image?.size
        if let animatedImage = animatedImage {
            imageView.image = animatedImage[currentImageIndex]
        } else {
            imageView.image = displayingImage
        }
        if oldImageSize != imageView.image?.size || cropImagesToNonTransparent {
            layout()
        }

    }
    
    var imagesCount: Int {
        animatedImage?.count ?? images.count
    }
    
    /// The image frame position.
    public enum FramePosition: Hashable {
        /// The first image.
        case first
        /// The last image.
        case last
        /// A random image.
        case random
        /// The next image.
        case next
        /// The next image looped.
        case nextLooped
        /// The previous image.
        case previous
        /// The previous image looped.
        case previousLooped
        /// The image at the index.
        case index(Int)
    }
    
    /// Sets the displaying image to the specified position.
    open func setImageFrame(to position: FramePosition) {
        guard imagesCount > 0 else { return }
        switch position {
        case let .index(index):
            if index >= 0, index < imagesCount {
                currentImageIndex = index
            }
        case .first:
            currentImageIndex = 0
        case .last:
            currentImageIndex = imagesCount - 1
        case .random:
            currentImageIndex = Int.random(in: 0 ... imagesCount - 1)
        case .next:
            currentImageIndex += 1
            if currentImageIndex >= imagesCount {
                currentImageIndex = imagesCount - 1
            }
        case .nextLooped:
            currentImageIndex += 1
            if currentImageIndex >= imagesCount {
                currentImageIndex = 0
            }
        case .previous:
            currentImageIndex -= 1
            if currentImageIndex < 0 {
                currentImageIndex = 0
            }
        case .previousLooped:
            currentImageIndex -= 1
            if currentImageIndex < 0 {
                currentImageIndex = imagesCount - 1
            }
        }
    }
    
    open override func alignmentRect(forFrame frame: NSRect) -> NSRect {
        imageView.alignmentRect(forFrame: frame)
    }

    open override func frame(forAlignmentRect alignmentRect: NSRect) -> NSRect {
        imageView.frame(forAlignmentRect: alignmentRect)
    }
    
    open override var firstBaselineOffsetFromTop: CGFloat {
        imageView.firstBaselineOffsetFromTop
    }
    
    open override var lastBaselineOffsetFromBottom: CGFloat {
        imageView.lastBaselineOffsetFromBottom
    }
    
    open override var baselineOffsetFromBottom: CGFloat {
        imageView.baselineOffsetFromBottom
    }
    
    /*
    open override var firstBaselineAnchor: NSLayoutYAxisAnchor {
        get { imageView.firstBaselineAnchor }
    }
    
    open override var lastBaselineAnchor: NSLayoutYAxisAnchor {
        get { imageView.lastBaselineAnchor }
    }
     */
    
    open override func hitTest(_ point: NSPoint) -> NSView? {
        let view = super.hitTest(point)
        if isSelectable == .byView {
            return view
        } else if isSelectable == .byImage && overlayContentView.frame.contains(point) {
            return view
        } else if animationPlayback == .onMouseClick, overlayContentView.frame.contains(point) {
            return view
        }
        return nil
    }
    
    open override var canBecomeKeyView: Bool {
        false
    }
    
    open override var acceptsFirstResponder: Bool { false }
        
    open override func drawFocusRingMask() {
        NSBezierPath(roundedRect: focusRingMaskBounds, cornerRadius: isSelectable == .byImage ?  imageCornerRadius : cornerRadius).fill()
    }
    
    open override var focusRingMaskBounds: NSRect {
        isSelectable == .byImage ? overlayContentView.frame : bounds
    }
    
    class AnimatedImage {
        
        struct Frame {
            let image: NSImage?
            let duration: TimeInterval
            init(_ image: NSImage? = nil, duration: TimeInterval) {
                self.image = image
                self.duration = duration
            }
        }
                
        init?(_ image: NSImage) {
            guard let representation = image.bitmapImageRep, representation.frameCount > 1 else { return nil }
            self.image = image
            self.count = representation.frameCount
            self.loopCount = representation.loopCount
            for index in 0..<self.count {
                representation.currentFrame = index
                var frameDuration = representation.currentFrameDuration
                if frameDuration == .zero {
                    frameDuration = ImageSource.defaultFrameDuration
                }
                duration += frameDuration
                frames.append(Frame(nil, duration: frameDuration))
            }
            representation.currentFrame = 0
            
            DispatchQueue(label: "com.fzuikit.animatedImageQueue").async {
                for index in 0..<self.count {
                    representation.currentFrame = index
                    self.frames[index] = Frame(representation.cgImage?.nsImage, duration: self.frames[index].duration)
                }
            }
        }
        
        subscript(index: Int) -> NSImage? {
            frames[safe: index]?.image
        }
        
        let count: Int
        let loopCount: Int
        var duration: TimeInterval = 0.0
        let image: NSImage
        var frames: SynchronizedArray<Frame> = []
    }
    
    class ContainerView: NSView {
        let containerView = NSView()
        var didSetup = false
        var shadowObservation: KeyValueObservation?

        public override var subviews: [NSView] {
            get { didSetup ? containerView.subviews : super.subviews }
            set {
                if didSetup {
                    containerView.subviews = newValue
                } else {
                    super.subviews = newValue
                }
            }
        }
        
        public override func addSubview(_ view: NSView) {
            if didSetup {
                containerView.addSubview(view)
            } else {
                super.addSubview(view)
            }
        }
        
        public override var cornerRadius: CGFloat {
            didSet {
                containerView.cornerRadius = cornerRadius
                clipsToBounds = false
            }
        }
        
        public override var cornerCurve: CALayerCornerCurve {
            didSet { containerView.cornerCurve = cornerCurve }
        }
        
        public override var roundedCorners: CACornerMask {
            didSet { containerView.roundedCorners = roundedCorners }
        }
        
        /*
        public override var innerShadow: ShadowConfiguration {
            get { containerView.innerShadow }
            set { containerView.innerShadow = newValue }
        }
         */
        
        init() {
            super.init(frame: .zero)
            sharedInit()
        }
            
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            sharedInit()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            sharedInit()
        }
        
        func sharedInit() {
            wantsLayer = true
            clipsToBounds = false
            containerView.clipsToBounds = true
            addSubview(withConstraint: containerView)
            shadowObservation = observeChanges(for: \.layer?.shadowColor) { [weak self] _, new in
                guard let self = self else { return }
                self.layer?.backgroundColor = new
            }
            didSetup = true
        }
    }
}

extension ImageView.FramePosition: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .index(value)
    }
}

#endif
