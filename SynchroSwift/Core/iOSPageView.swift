//
//  iOSPageView.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/14/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSPageView");

class PageContentScrollView : UIScrollView
{
    var _content: iOSControlWrapper?;
    
    internal init(frame: CGRect, content: iOSControlWrapper?)
    {
        super.init(frame: frame);
        _content = content;
        if (_content != nil)
        {
            self.addSubview(_content!.control!);
        }
    }

    // Subclasses required to implement...
    //
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func layoutSubviews()
    {
        if (!self.isDragging && !self.isDecelerating)
        {
            // Util.debug("Laying out sub view");
            if (_content != nil)
            {
                // Size child (content) to parent as appropriate
                //
                var frame = _content!.control!.frame;
                var frameSize = frame.size;
                
                if (_content!.frameProperties.heightSpec == SizeSpec.fillParent)
                {
                    frameSize.height = self.frame.height;
                }
                
                if (_content!.frameProperties.widthSpec == SizeSpec.fillParent)
                {
                    frameSize.width = self.frame.width;
                }
                
                frame.size = frameSize;
                _content!.control!.frame = frame;
                
                // Set scroll content area based on size of contents
                //
                var size = CGSize(width: self.contentSize.width, height: self.contentSize.height);
                
                // Size width of scroll content area to container width (to achieve vertical-only scroll)
                size.width = self.superview!.frame.width;
                
                // Size height of scroll content area to height of contained views...
                size.height = _content!.control!.frame.y + _content!.control!.frame.height;
                
                self.contentSize = size;
            }
        }
        
        super.layoutSubviews();
    }
}

open class iOSPageView : PageView, UINavigationBarDelegate, UIGestureRecognizerDelegate
{
    var _pageTitle = "";
    
    var _viewController: UIViewController;
    var _rootControlWrapper: iOSControlWrapper?;
    var _contentScrollView: PageContentScrollView?;
    
    var _navBar: UINavigationBar?;
    var _navBarButton: UIBarButtonItem?;
    
    var _toolBar: UIToolbar?;
    var _toolBarButtons = [UIBarButtonItem]();
        
    public init(stateManager: StateManager, viewModel: ViewModel, viewController: UIViewController, panel: UIView, launchedFromMenu: Bool)
    {
        _viewController = viewController;
        super.init(stateManager: stateManager, viewModel: viewModel, launchedFromMenu: launchedFromMenu);

        _rootControlWrapper = iOSControlWrapper(pageView: self, stateManager: _stateManager, viewModel: _viewModel, bindingContext: _viewModel.rootBindingContext, control: panel);

        self.setPageTitle = {(title) in self._pageTitle = title };
    
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardShown), name: NSNotification.Name.UIKeyboardDidShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboardHidden), name: NSNotification.Name.UIKeyboardDidHide, object: nil);

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap));
        tap.delegate = self;
        tap.cancelsTouchesInView = false;
        _rootControlWrapper!.control!.addGestureRecognizer(tap);
    }

    deinit
    {
        NotificationCenter.default.removeObserver(self);
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        return !(touch.view is UIButton)
    }

    @objc func handleTap(_ recognizer: UITapGestureRecognizer)
    {
        _rootControlWrapper!.control!.endEditing(true);
    }
    
    @objc func onKeyboardShown(_ notification: Notification)
    {
        // May want animate this at some point - see: https://gist.github.com/redent/7263276
        //
        let keyboardFrame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue;
        logger.debug("Keyboard shown - frame: \(keyboardFrame)");

        if let scrollView = _contentScrollView
        {
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0);
            scrollView.contentInset = contentInsets;
            scrollView.scrollIndicatorInsets = contentInsets;
            
            centerScrollView();
        }
    }
    
    @objc func onKeyboardHidden(_ notification: Notification)
    {
        logger.debug("Keyboard hidden");
        if let scrollView = _contentScrollView
        {
            scrollView.contentInset = UIEdgeInsets.zero;
            scrollView.scrollIndicatorInsets = UIEdgeInsets.zero;
        }
    }
    
    open class func findFirstResponder(_ view: UIView?) -> UIView?
    {
        if let view = view
        {
            if (view.isFirstResponder)
            {
                return view;
            }
            
            for subView in view.subviews
            {
                if let firstResponder = findFirstResponder(subView)
                {
                    return firstResponder;
                }
            }
        }
        return nil;
    }
    
    // Center the scroll view on the active edit control.
    //
    open func centerScrollView()
    {
        // We could use this any time the edit control focus changed, on the "return" in an edit control, etc.
        //
        if let activeView = iOSPageView.findFirstResponder(_contentScrollView)
        {
            var activeViewRect = activeView.superview!.convert(activeView.frame, from: _contentScrollView);
            let scrollAreaHeight = _contentScrollView!.frame.height - _contentScrollView!.contentInset.bottom;
            
            let offset = max(0, activeViewRect.y - (scrollAreaHeight - activeView.frame.height) / 2);
            _contentScrollView!.setContentOffset(CGPoint(x: 0, y: offset), animated: false);
        }
    }
    
    open override func createRootContainerControl(_ controlSpec: JObject) -> ControlWrapper?
    {
        return iOSControlWrapper.createControl(_rootControlWrapper!, bindingContext: _viewModel.rootBindingContext, controlSpec: controlSpec);
    }
    
    // !!! The ContentTop and SizeNavBar methods below are a pretty ugly hack to address the issues with navigation bar
    //     sizing/positioning in iOS7 and later.  iOS7 and later is supposed to magically handle all of this, and if
    //     not, then NavigationBarDelegate.GetPositionForBar() fix is supposed to do the job, but it does not
    //     in our case.  I assume this is because we create our navbar on the fly, after the ViewController is
    //     created.
    //
    open class var contentTop: CGFloat
    {
        get
        {
            let statusBarSize = UIApplication.shared.statusBarFrame.size
            return Swift.min(statusBarSize.width, statusBarSize.height)
        }
    }
    
    open class func sizeNavBar(_ navBar: UINavigationBar)
    {
        navBar.sizeToFit();
        navBar.frame = CGRect(x: navBar.frame.x, y: contentTop, width: navBar.frame.width, height: navBar.frame.height);
    }

    open func updateLayout()
    {
        logger.debug("updateLayout starting...");

        // Equivalent in concept to LayoutSubviews (but renamed to avoid confusion, since PageView isn't a UIView)
        //
        // This is currently only called on orientation change
        //
        if let panel: UIView = _rootControlWrapper!.control
        {
            var contentRect = CGRect(x: 0, y: iOSPageView.contentTop, width: panel.bounds.width, height: panel.bounds.height - iOSPageView.contentTop);
            
            if (_navBar != nil)
            {
                iOSPageView.sizeNavBar(_navBar!);
                contentRect = CGRect(x: contentRect.x, y: contentRect.y + _navBar!.frame.height, width: contentRect.width, height: contentRect.height - _navBar!.frame.height);
            }
            
            if (_toolBar != nil)
            {
                _toolBar!.sizeToFit();
                _toolBar!.frame = CGRect(x: contentRect.x, y: contentRect.y + contentRect.height - _toolBar!.frame.height, width: contentRect.width, height: _toolBar!.frame.height);
                contentRect = CGRect(x: contentRect.x, y: contentRect.y, width: contentRect.width, height: contentRect.height - _toolBar!.bounds.height);
            }
            
            if let scrollView = _contentScrollView
            {
                scrollView.frame = contentRect;
            }
        }
        logger.debug("updateLayout finished");
    }

    open override func clearContent()
    {
        logger.debug("clearing content");
        
        _navBar = nil;
        _navBarButton = nil;
        
        _toolBar = nil;
        _toolBarButtons.removeAll(keepingCapacity: false);
        
        if let panel = _rootControlWrapper!.control
        {
            for subview in panel.subviews
            {
                // There was a special case when transitioning to a page that triggered location permission, the OS put
                // up an alert view to confirm location services as we were bulding the new page (when it encountered the
                // "location" control).  Without the check below, we actually took down the system alert view a half-second
                // or so later when we swapped in our new page.
                //
                if (!(subview is UIAlertView))
                {
                    subview.removeFromSuperview();
                }
            }
        }
        _rootControlWrapper!.clearChildControls();
        _contentScrollView = nil;
    }

    open func setNavBarButton(_ button: UIBarButtonItem)
    {
        _navBarButton = button;
        if (_navBar != nil)
        {
            // Due to a bug in positioning the right bar button image when the image is changed,
            // we have to clear out the right bar button reference and reset it whenever the
            // image changes.
            //
            _navBar!.topItem!.rightBarButtonItem = nil;
            _navBar!.topItem!.rightBarButtonItem = _navBarButton;
        }
    }

    open func addToolbarButton(_ button: UIBarButtonItem)
    {
        _toolBarButtons.append(button);
    }

    // UINavigationBarDelegate
    open func position(for barPositioning: UIBarPositioning) -> UIBarPosition
    {
        // Per several recommendations, especially this one: http://blog.falafel.com/ios-7-bars-with-xamarinios/
        //
        // !!! This is supposed to fix the Navbar positioning on iOS7, but doesn't do anything for us...
        //
        return UIBarPosition.topAttached;
    }
    
    // UINavigationBarDelegate
    open func navigationBar(_ navigationBar: UINavigationBar, shouldPop shouldPopItem: UINavigationItem) -> Bool
    {
        logger.debug("Should pop item got called!");
        self.goBack();
        return false;
    }

    open override func setContent(_ content: ControlWrapper?)
    {
        logger.debug("Setting content");
        
        if let panel: UIView = _rootControlWrapper!.control
        {
            var contentRect = CGRect(x: 0, y: iOSPageView.contentTop, width: panel.frame.width, height: panel.frame.height - iOSPageView.contentTop);
            
            // Apply any margins of the top-level control here.
            //
            // Note that generally the top-level control will be a container and not have a margin.  Note
            // also that this margin inset is done at the time the content is set, so the applied margin 
            // will not updated after that point (the margin property cannot be animated in this case).
            // This is really to handle the "Hello World" case of a standalone non-container top-level 
            // control that we don't want jammed into the upper left corner.
            //
            if let iOSControl = content as? iOSControlWrapper
            {
                contentRect = UIEdgeInsetsInsetRect(contentRect, iOSControl.margin)
            }
            
            // Create the nav bar, add a back control as appropriate...
            //
            _navBar = UINavigationBar();
            _navBar!.delegate = self;
            iOSPageView.sizeNavBar(_navBar!);
            
            if (self.hasBackCommand)
            {
                // Add a "Back" context and a delegate to handle the back command...
                //
                let navItemBack = UINavigationItem(title: "Back");
                _navBar!.pushItem(navItemBack, animated: false);
            }
            
            let navItem = UINavigationItem(title: _pageTitle);
            
            if (_navBarButton != nil)
            {
                navItem.setRightBarButton(_navBarButton!, animated: false);
            }

            // When starting in Landscape orientation, there was a bug where the initial vertical position of the back arrow was not correct (was
            // aligned to the very top of the nav bar).  The statement below appears to remedy this issue.
            //
            _navBar?.layoutIfNeeded();
            
            _navBar!.pushItem(navItem, animated: false);
            panel.addSubview(_navBar!);
            
            // Adjust content rect based on navbar.
            //
            contentRect = CGRect(x: contentRect.x, y: contentRect.y + _navBar!.bounds.height, width: contentRect.width, height: contentRect.height - _navBar!.bounds.height);
            
            _toolBar = nil;
            if (_toolBarButtons.count > 0)
            {
                // Create toolbar, position it at the bottom of the screen, adjust content rect to represent remaining space
                //
                _toolBar = UIToolbar();
                _toolBar!.barStyle = UIBarStyle.default;
                _toolBar!.sizeToFit();
                _toolBar!.frame = CGRect(x: contentRect.x, y: contentRect.y + contentRect.height - _toolBar!.frame.height, width: contentRect.width, height: _toolBar!.frame.height);
                contentRect = CGRect(x: contentRect.x, y: contentRect.y, width: contentRect.width, height: contentRect.height - _toolBar!.bounds.height);
                
                // Create a new colection of toolbar buttons with flexible space surrounding and between them, then add to toolbar
                //
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil);
                var formattedItems = [UIBarButtonItem]();
                formattedItems.append(flexibleSpace);
                for buttonItem in _toolBarButtons
                {
                    formattedItems.append(buttonItem);
                    formattedItems.append(flexibleSpace);
                }
                _toolBar!.items = formattedItems;
                
                panel.addSubview(_toolBar!);
            }
            
            // Create the main content area (scroll view) and add the page content to it...
            //
            _contentScrollView = PageContentScrollView(frame: contentRect, content: content as? iOSControlWrapper);
            panel.addSubview(_contentScrollView!);
            if (content != nil)
            {
                // We're adding the content to the _rootControlWrapper child list, even thought the scroll view
                // is actually in between (in the view heirarchy) - but that shouldn't be a problem.
                _rootControlWrapper!.addChildControl(content!);
            }
        }
        
        logger.debug("Done setting content");
    }

    //
    // MessageBox stuff...
    //

    open override func processMessageBox(_ messageBox: JObject, onCommand: @escaping CommandHandler)
    {
        var message = "";
        if (messageBox["message"] != nil)
        {
            message = PropertyValue.expandAsString(messageBox["message"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
            logger.debug("Message box with message: \(message)");
        }
 
        var title: String?;
        if (messageBox["title"] != nil)
        {
            title = PropertyValue.expandAsString(messageBox["title"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        if let options = messageBox["options"] as? JArray
        {
            for option in options
            {
                if let optionObject = option as? JObject
                {
                    let buttonTitle = PropertyValue.expandAsString(optionObject["label"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
                    var buttonCommand: String? = nil;
                    if (optionObject["command"] != nil)
                    {
                        buttonCommand = PropertyValue.expandAsString(optionObject["command"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
                    }
                    
                    alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertActionStyle.default, handler:
                    { (action: UIAlertAction) in
                        if (buttonCommand != nil)
                        {
                            onCommand(buttonCommand!);
                        }
                    }))
                }
            }
        }
        else
        {
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil));
        }
        
        _viewController.present(alert, animated: true, completion: nil)
    }
    
    open override func processLaunchUrl(_ primaryUrl: String, secondaryUrl: String?)
    {
        // You could use canOpenUrl to check, but there is a whole security shitshow associated with that (limits on the number of
        // schemes you can check over the lifetime of the app on iOS 8, and a requirement to whitelist any scheme that you might check
        // on iOS 9).  So for our purposes, just attempting to open and falling back if that returns false should work fine, while
        // avoiding all of the complexity of canOpenUrl.
        //
        let primaryNsUrl = URL(string: primaryUrl);
        if (primaryNsUrl != nil)
        {
            if (!UIApplication.shared.openURL(primaryNsUrl!) && (secondaryUrl != nil))
            {
                let secondaryNsUrl = URL(string: secondaryUrl!);
                if (secondaryNsUrl != nil)
                {
                    UIApplication.shared.openURL(URL(string: secondaryUrl!)!);
                }
            }
        }
    }
    
    open override func processChoosePhoto(_ request: JObject, onComplete: (JObject) -> Void)
    {
        // !!! TODO - Implement this
        //
        //     I played around with UIImagePickerController and had some issues with it.  I think the proper solution is probably
        //     to build a custom image picker that supports either camera, or camera roll/saved images, or a specified combination.
        //     UIImagePickerController, in addition to generally not working at all, is limited to either camera or saved images, and
        //     is always in portrait mode.
        //
        //     Also, the new view that we make to do this can handle status indication when any selected image is being uploaded, before
        //     returning.
        //
        logger.error("processChoosePhoto not imeplemented yet");
    }
}

