//
//  USeekPlayerViewController.swift
//  Pods-USeek-Swift_Example
//
//  Created by Chris Lin on 10/8/17.
//

import UIKit
import WebKit

/**
 *
 * The USeekPlayerViewControllerDelegate protocol provides a mechanism for your application
 * to take action on events that occur in the USeekWebView. You can make use of these calls
 * by assigning an object to the USeekPlayerViewController's delegate property directly.
 *
 */
@objc public protocol USeekPlayerViewControllerDelegate: NSObjectProtocol {
    
    /**
     *
     * Called when USeekPlayerViewController detected an error while loading the video.
     *
     * @param playerViewController          The USeekPlayerViewController object which initiated this event.
     * @param error                         The NSError object with error information.
     *
     */
    @objc optional func useekPlayerViewController (_ playerViewController: USeekPlayerViewController, didFailWithError error: Error)
    
    /**
     *
     * Called when USeekPlayerViewController starts loading the video.
     *
     * @param playerViewController          The USeekPlayerViewController object which initiated this event.
     *
     */
    @objc optional func useekPlayerViewControllerDidStartLoad (_ playerViewController: USeekPlayerViewController)
    
    /**
     *
     * Called when USeekPlayerViewController finished loading the video.
     *
     * @param playerViewController          The USeekPlayerViewController object which initiated this event.
     *
     */
    @objc optional func useekPlayerViewControllerDidFinishLoad (_ playerViewController: USeekPlayerViewController)
    
    /**
     *
     * Called when user clicked close button to dismiss the USeekPlayerViewController
     *
     * @param playerViewController          The USeekPlayerView object which initiated this event.
     *
     */
    @objc optional func useekPlayerViewControllerDidClose (_ playerViewController: USeekPlayerViewController)
}

/**
 *
 * This class inherits UIView, which you can easily drop in storyboard or create anywhere in your code.
 *
 * There are 2 ways to use USeekPlayerView.
 *
 * - Add as a subview programmatically
 *
 *      ```objective-c
 *      USeekPlayerView *playerView = [[USeekPlayerView alloc] initWithFrame:CGRectMake(0, 0, 100, 60)];
 *      [self.view addSubview:playerView];
 *      ```
 *
 * - Add in storyboard
 *
 * Just change the class name of the view to USeekPlayerView in storyboard.
 * Now you can add the view as IBOutlet and use.
 *
 */
public class USeekPlayerViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
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
    weak public var delegate: USeekPlayerViewControllerDelegate?
    
    @IBOutlet weak var viewContainer: UIView!
    @IBOutlet weak var loadingMaskView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    var webView: WKWebView!
    
    var status: VideoLoadStatus = .none
    var isLoadingMaskHidden: Bool = false
    var isCloseButtonHidden: Bool = false
    
    var gameId: String = ""
    var userId: String = ""
    
    public init() {
        let bundle = Bundle(for: type(of: self))
        let nibName = type(of: self).description().components(separatedBy: ".").last!
        super.init(nibName: nibName, bundle: bundle)
        self.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initialize () {
        self.isCloseButtonHidden = false
        self.isLoadingMaskHidden = false
        
        guard let _ = self.view else {
            print("USeekPlayerViewController is not properly initiated. Aborting...")
            return
        }
        
        self.initializeWebview()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.closeButton.isHidden = self.isCloseButtonHidden
        
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    }
    
    func initializeWebview () {
        let config: WKWebViewConfiguration = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypes.all
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.viewContainer.frame.width, height: self.viewContainer.frame.height), configuration: config);
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        self.webView.uiDelegate = self;
        self.webView.navigationDelegate = self;
        self.viewContainer.addSubview(self.webView);
    }
    
    // Orientation
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
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
            print("USeekPlayerViewController is not properly initiated. Aborting...")
            return
        }
        
        self.gameId = gameId
        self.userId = userId ?? ""
        if self.validateConfiguration() == false {
            return
        }
        
        self.status = .none
        self.loadingMaskView.isHidden = true
        
        guard let url = self.generateVideoUrl() else {
            print("Useek Configuration Invalid. Aborting...")
            return
        }
        
        let urlReq: URLRequest = URLRequest(url: url)
        self.webView.isOpaque = false
        self.webView.backgroundColor = UIColor.clear
        self.webView.load(urlReq)
    }
    
    /**
     *
     * Validates the configuration.
     * If any of publisher id or game id is not set, validation fails.
     *
     */
    public func validateConfiguration () -> Bool {
        if USeekUtils.validateString(USeekManager.sharedManager.publisherId) == false {
            return false
        }
        if USeekUtils.validateString(self.gameId) == false {
            return false
        }
        return true
    }
    
    public func setLoadingMaskHidden (_ hidden: Bool) {
        self.isLoadingMaskHidden = hidden
        if self.loadingMaskView != nil {
            self.loadingMaskView.isHidden = hidden
        }
    }
    
    public func generateVideoUrl () -> URL? {
        if self.validateConfiguration() == false {
            return nil
        }
        
        var urlString = "https://www.useek.com/sdk/1.0/\(USeekManager.sharedManager.publisherId)/\(self.gameId)/play"
        if USeekUtils.validateString(self.userId) == true {
            urlString = "\(urlString)?external_user_id=\(self.userId)"
        }
        if USeekUtils.validateUrl(urlString) == false {
            return nil
        }
        
        return URL(string: urlString)
    }
    
    /**
     *
     * Show / hide close button in USeekPlayerViewController
     *
     * @param hidden        YES to hide the close button, NO to show
     *
     */
    public func setCloseButtonHidden (_ hidden: Bool) {
        self.isCloseButtonHidden = hidden
        if self.closeButton != nil {
            self.closeButton.isHidden = hidden
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
    
    @IBAction func onCloseButtonClick(_ sender: Any) {
        print("USeekPlayerViewController didClose")
        self.delegate?.useekPlayerViewControllerDidClose?(self)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: WKNavigationDelegate
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("USeekWebView didStartLoad")
        
        if self.status == .none {
            self.delegate?.useekPlayerViewControllerDidStartLoad?(self)
        }
        
        self.status = .load_started
        if self.isLoadingMaskHidden == false {
            self.animateLoadingMaskToShow()
        }
        else {
            self.loadingMaskView.isHidden = true
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("USeekWebView didFinishLoad")
        
        if self.status != .load_failed && self.status != .loaded {
            self.delegate?.useekPlayerViewControllerDidFinishLoad?(self)
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
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("USeekWebView didFailLoadWithError: \(error)")
        
        if self.status != .load_failed {
            self.delegate?.useekPlayerViewController?(self, didFailWithError: error)
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
