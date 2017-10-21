//
//  USeekPlayerView.swift
//  Pods-USeek-Swift_Example
//
//  Created by Chris Lin on 10/8/17.
//

import UIKit

/**
 *
 * The USeekPlayerViewDelegate protocol provides a mechanism for your application to take
 * action on events that occur in the USeekWebView. You can make use of these calls by
 * assigning an object to the USeekPlayerView's delegate property directly.
 *
 */
@objc public protocol USeekPlayerViewDelegate: NSObjectProtocol {
    
    /**
     *
     * Called when USeekPlayerView detected an error while loading the video.
     *
     * @param playerView        The USeekPlayerView object which initiated this event.
     * @param error             The NSError object with error information.
     *
     */
    @objc optional func useekPlayerView (_ playerView: USeekPlayerView, didFailWithError error: Error)
    
    /**
     *
     * Called when USeekPlayerView starts loading the video.
     *
     * @param playerView        The USeekPlayerView object which initiated this event.
     *
     */
    @objc optional func useekPlayerViewDidStartLoad(_ playerView: USeekPlayerView)
    
    /**
     *
     * Called when USeekPlayerView finished loading the video.
     *
     * @param playerView        The USeekPlayerView object which initiated this event.
     *
     */
    @objc optional func useekPlayerViewDidFinishLoad(_ playerView: USeekPlayerView)
    
}

/**
 *
 * This class inherits UIView, which you can easily drop in storyboard or create anywhere in your code.
 *
 * There are 2 ways to use USeekPlayerView.
 *
 * - Add as a subview programmatically
 *
 *      ```swift
 *      let playerView = USeekPlayerView(frame: CGRect(x: 0, y: 0, width: 320, height: 400))
 *      self.view.addSubview(playerView)
 *      ```
 *
 * - Add in storyboard
 *
 * Just change the class name of the view to USeekPlayerView in storyboard.
 * Now you can add the view as IBOutlet and use.
 *
 */
public class USeekPlayerView: UIView, UIWebViewDelegate {
    
    /**
     *
     * IBOutlet for the loading label.
     * By using this label, you can customize the loading text, color and fonts.
     *
     */
    @IBOutlet weak public var loadingTitleLabel: UILabel!
    
    /**
     *
     * The delegate can be used to handle the events occured while playing video.
     *
     */
    weak public var delegate: USeekPlayerViewDelegate?
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var loadingMaskView: UIView!
    @IBOutlet weak var webView: USeekWebView!
    
    var status: VideoLoadStatus = .none
    var isLoadingMaskHidden: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        self.initialize()
    }
    
    func initialize () {
        let className = String(describing: USeekPlayerView.self)
        Bundle.main.loadNibNamed(className, owner: self, options: nil)
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.addSubview(self.view)
        
        self.status = .none
        self.isLoadingMaskHidden = false
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: Utility Methods
    
    /**
     *
     * Starts loading the video in UIWebView instance.
     *
     * - Precondition: Publisher ID should be set.
     *
     * @param gameId      unique game id provided by USeek, not nullable.
     * @param userId      user's unque id registered in USeek, nullable.
     *
     */
    public func loadVideo(GameId gameId: String, UserId userId: String?) {
        guard let _ = self.view else {
            print("USeekPlayerView is not properly initiated. Aborting...")
            return
        }
        
        self.webView.gameId = gameId
        self.webView.userId = userId ?? ""
        if self.validateConfiguration() == false {
            return
        }
        
        self.webView.delegate = self
        self.status = .none
        self.loadingMaskView.isHidden = true
        
        self.webView.loadVideo()
    }
    
    /**
     *
     * Validates the configuration.
     * If any of publisher id or game id is not set, validation fails.
     *
     */
    func validateConfiguration () -> Bool {
        return self.webView.validateConfiguration()
    }
    
    public func setLoadingMaskHidden (_ hidden: Bool) {
        self.isLoadingMaskHidden = hidden
        if self.loadingMaskView != nil {
            self.loadingMaskView.isHidden = hidden
        }
    }
    
    // MARK: UI
    
    func animateLoadingMaskToShow () {
        if self.loadingMaskView.isHidden == false {
            return
        }
        
        self.loadingMaskView.isHidden = false
        self.loadingMaskView.alpha = 0
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.loadingMaskView.alpha = 1
            }, completion: { (completed: Bool) in
                self.loadingMaskView.alpha = 1
            })
        }
    }
    
    func animateLoadingMaskToHide () {
        if self.loadingMaskView.isHidden == true {
            return
        }
        
        self.loadingMaskView.isHidden = false
        self.loadingMaskView.alpha = 1
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.loadingMaskView.alpha = 0
            }, completion: { (completed: Bool) in
                self.loadingMaskView.alpha = 1
                self.loadingMaskView.isHidden = true
            })
        }
    }
    
    // MARK: UIWebViewDelegate
    
    public func webViewDidStartLoad(_ webView: UIWebView) {
        print("USeekWebView didStartLoad")
        
        if self.status == .none {
            self.delegate?.useekPlayerViewDidStartLoad?(self)
        }
        
        self.status = .load_started
        if self.isLoadingMaskHidden == false {
            self.animateLoadingMaskToShow()
        }
        else {
            self.loadingMaskView.isHidden = true
        }
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        print("USeekWebView didFinishLoad")
        
        if self.status != .load_failed && self.status != .loaded {
            self.delegate?.useekPlayerViewDidFinishLoad?(self)
        }
        
        if self.status != .load_failed {
            self.status = .loaded
        }
        
        if self.isLoadingMaskHidden == false {
            self .animateLoadingMaskToHide()
        }
        else {
            self.loadingMaskView.isHidden = true
        }
    }
    
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("USeekWebView didFailLoadWithError: \(error)")
        
        if self.status != .load_failed {
            self.delegate?.useekPlayerView?(self, didFailWithError: error)
        }
        
        self.status = .load_failed
        if self.isLoadingMaskHidden == false {
            self.animateLoadingMaskToHide()
        }
        else {
            self.loadingMaskView.isHidden = true
        }
    }
}

