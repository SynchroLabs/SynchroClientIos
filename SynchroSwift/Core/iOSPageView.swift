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

class SynchroNavigationBarDelegate : NSObject, UINavigationBarDelegate
{
    var _pageView: iOSPageView;
    
    internal init(pageView: iOSPageView)
    {
        _pageView = pageView;
    }
    
    // Per several recommendations, especially this one: http://blog.falafel.com/ios-7-bars-with-xamarinios/
    //
    // !!! This is supposed to fix the Navbar positioning on iOS7, but doesn't do anything for us...
    //
    internal func getPositionForBar(barPositioning: UIBarPositioning) -> UIBarPosition
    {
        return UIBarPosition.TopAttached;
    }
    
    internal func shouldPopItem(navigationBar: UINavigationBar, item: UINavigationItem) -> Bool
    {
        logger.debug("Should pop item got called!");
        _pageView.goBack();
        return false;
    }
}

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
    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func layoutSubviews()
    {
        if (!self.dragging && !self.decelerating)
        {
            // Util.debug("Laying out sub view");
            if (_content != nil)
            {
                // Size child (content) to parent as appropriate
                //
                var frame = _content!.control!.frame;
                var frameSize = frame.size;
                
                if (_content!.frameProperties.heightSpec == SizeSpec.FillParent)
                {
                    frameSize.height = self.frame.height;
                }
                
                if (_content!.frameProperties.widthSpec == SizeSpec.FillParent)
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

public class iOSPageView : PageView
{
    var _pageTitle = "";
    
    var _viewController: UIViewController;
    var _rootControlWrapper: iOSControlWrapper?;
    var _contentScrollView: PageContentScrollView?;
    
    var _navBar: UINavigationBar?;
    var _navBarButton: UIBarButtonItem?;
    
    var _toolBar: UIToolbar?;
    var _toolBarButtons = [UIBarButtonItem]();
    
    public init(stateManager: StateManager, viewModel: ViewModel, viewController: UIViewController, panel: UIView, doBackToMenu: (() -> Void))
    {
        _viewController = viewController;
        super.init(stateManager: stateManager, viewModel: viewModel, doBackToMenu);

        _rootControlWrapper = iOSControlWrapper(pageView: self, stateManager: _stateManager, viewModel: _viewModel, bindingContext: _viewModel.rootBindingContext, control: panel);

        self.setPageTitle = {(title) in self._pageTitle = title };
    
        // http://stackoverflow.com/questions/24097831/how-to-move-content-of-uiviewcontroller-upwards-as-keypad-appears-using-swift
        // http://stackoverflow.com/questions/24007650/selector-in-swift
        //
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onKeyboardShown:"), name: UIKeyboardDidShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onKeyboardHidden:"), name: UIKeyboardDidHideNotification, object: nil);

        DismissKeyboardOnBackgroundTap();
    }

    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self);
    }
    
    func DismissKeyboardOnBackgroundTap()
    {
        class GestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate
        {
            override init()
            {
                super.init();
            }
            
            func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool
            {
                return !(touch.view is UIButton)
            }
        }

        // Add gesture recognizer to hide keyboard on tap
        var tap = UITapGestureRecognizer(target: self, action: Selector("handleTap:"));
        tap.delegate = GestureRecognizerDelegate();
        tap.cancelsTouchesInView = false;
        tap.addTarget(self, action: Selector("handleTap:"));
        _rootControlWrapper!.control!.addGestureRecognizer(tap);
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer)
    {
        _rootControlWrapper!.control!.endEditing(true);
    }
    
    @objc func onKeyboardShown(notification: NSNotification)
    {
        // May want animate this at some point - see: https://gist.github.com/redent/7263276
        //
        let keyboardFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue();
        logger.debug("Keyboard shown - frame: \(keyboardFrame)");

        if let scrollView = _contentScrollView
        {
            var contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardFrame.height, right: 0.0);
            scrollView.contentInset = contentInsets;
            scrollView.scrollIndicatorInsets = contentInsets;
            
            centerScrollView();
        }
    }
    
    @objc func onKeyboardHidden(notification: NSNotification)
    {
        logger.debug("Keyboard hidden");
        if let scrollView = _contentScrollView
        {
            scrollView.contentInset = UIEdgeInsetsZero;
            scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
        }
    }
    
    public class func findFirstResponder(view: UIView?) -> UIView?
    {
        if let view = view
        {
            if (view.isFirstResponder())
            {
                return view;
            }
            
            for subView in view.subviews
            {
                if let firstResponder = findFirstResponder(subView as? UIView)
                {
                    return firstResponder;
                }
            }
        }
        return nil;
    }
    
    // Center the scroll view on the active edit control.
    //
    public func centerScrollView()
    {
        // We could use this any time the edit control focus changed, on the "return" in an edit control, etc.
        //
        if let activeView = iOSPageView.findFirstResponder(_contentScrollView)
        {
            var activeViewRect = activeView.superview!.convertRect(activeView.frame, fromView: _contentScrollView);
            var scrollAreaHeight = _contentScrollView!.frame.height - _contentScrollView!.contentInset.bottom;
            
            var offset = max(0, activeViewRect.y - (scrollAreaHeight - activeView.frame.height) / 2);
            _contentScrollView!.setContentOffset(CGPoint(x: 0, y: offset), animated: false);
        }
    }
    
    public override func createRootContainerControl(controlSpec: JObject) -> ControlWrapper?
    {
        return iOSControlWrapper.createControl(_rootControlWrapper!, bindingContext: _viewModel.rootBindingContext, controlSpec: controlSpec);
    }
    
    // !!! The ContentTop and SizeNavBar methods below are a pretty ugly hack to address the issues with
    //     navigation bar sizing/positioning in iOS7.  iOS7 is supposed to magically handle all of this, and if
    //     not, then NavigationBarDelegate.GetPositionForBar() fix is supposed to do the job, but it does not
    //     in our case.  I assume this is because we create our navbar on the fly, after the ViewController is
    //     created.  I tried a number of ways to get this to work across iOS 6 and 7 without checking the version
    //     number and using a hardcoded status bar height, but was not able to make it work.
    //
    public class var contentTop: CGFloat
    {
        get
        {
            if (Util.isIOS7())
            {
                return 20; // Height of status bar in iOS7
            }

            return 0;
        }
    }

    public class func sizeNavBar(navBar: UINavigationBar)
    {
        navBar.sizeToFit();
        if (Util.isIOS7())
        {
            navBar.frame = CGRect(x: navBar.frame.x, y: contentTop, width: navBar.frame.width, height: navBar.frame.height);
        }
    }

    public func updateLayout()
    {
        // Equivalent in concept to LayoutSubviews (but renamed to avoid confusion, since PageView isn't a UIView)
        //
        if let panel: UIView = _rootControlWrapper!.control
        {
            var contentRect = CGRect(x: 0, y: iOSPageView.contentTop, width: panel.frame.width, height: panel.frame.height - iOSPageView.contentTop);
            
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
    }

    public override func clearContent()
    {
        _navBar = nil;
        _navBarButton = nil;
        
        _toolBar = nil;
        _toolBarButtons.removeAll(keepCapacity: false);
        
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

    public func setNavBarButton(button: UIBarButtonItem)
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

    public func addToolbarButton(button: UIBarButtonItem)
    {
        _toolBarButtons.append(button);
    }

    public override func setContent(content: ControlWrapper?)
    {
        if let panel: UIView = _rootControlWrapper!.control
        {
            var contentRect = CGRect(x: 0, y: iOSPageView.contentTop, width: panel.frame.width, height: panel.frame.height - iOSPageView.contentTop);
            
            // Create the nav bar, add a back control as appropriate...
            //
            _navBar = UINavigationBar();
            _navBar!.delegate = SynchroNavigationBarDelegate(pageView: self);
            iOSPageView.sizeNavBar(_navBar!);
            
            if (self.hasBackCommand)
            {
                // Add a "Back" context and a delegate to handle the back command...
                //
                var navItemBack = UINavigationItem(title: "Back");
                _navBar!.pushNavigationItem(navItemBack, animated: false);
            }
            
            var navItem = UINavigationItem(title: _pageTitle);
            
            if (_navBarButton != nil)
            {
                navItem.setRightBarButtonItem(_navBarButton!, animated: false);
            }
            
            _navBar!.pushNavigationItem(navItem, animated: false);
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
                _toolBar!.barStyle = UIBarStyle.Default;
                _toolBar!.sizeToFit();
                _toolBar!.frame = CGRect(x: contentRect.x, y: contentRect.y + contentRect.height - _toolBar!.frame.height, width: contentRect.width, height: _toolBar!.frame.height);
                contentRect = CGRect(x: contentRect.x, y: contentRect.y, width: contentRect.width, height: contentRect.height - _toolBar!.bounds.height);
                
                // Create a new colection of toolbar buttons with flexible space surrounding and between them, then add to toolbar
                //
                var flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil);
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
    }

    //
    // MessageBox stuff...
    //

    public override func processMessageBox(messageBox: JObject, onCommand: CommandHandler)
    {
        var message = PropertyValue.expandAsString(messageBox["message"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
        logger.debug("Message box with message: \(message)");
 
        var title: String?;
        if (messageBox["title"] != nil)
        {
            title = PropertyValue.expandAsString(messageBox["title"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
        }
        
        if let gotModernAlert: AnyClass = NSClassFromString("UIAlertController")
        {
            // Use UIAlertController (new hotness as of 8.0)
            //
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            
            if let options = messageBox["options"]? as? JArray
            {
                for option in options
                {
                    if let optionObject = option as? JObject
                    {
                        var buttonTitle = PropertyValue.expandAsString(optionObject["label"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
                        var buttonCommand: String? = nil;
                        if (optionObject["command"] != nil)
                        {
                            buttonCommand = PropertyValue.expandAsString(optionObject["command"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
                        }
                        
                        alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertActionStyle.Default, handler:
                        { (action: UIAlertAction!) in
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
                alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel, handler: nil));
            }
            
            _viewController.presentViewController(alert, animated: true, completion: nil)
        }
        else
        {
            // Use UIAlertView (deprecated as of 8.0, but only thing that works pre-8.0)
            //
            var alert = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: nil);
            
            var buttonCommands = [String?]();
            
            if let options = messageBox["options"]? as? JArray
            {
                for option in options
                {
                    if let optionObject = option as? JObject
                    {
                        var buttonTitle = PropertyValue.expandAsString(optionObject["label"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
                        var buttonCommand: String? = nil;
                        if (optionObject["command"] != nil)
                        {
                            buttonCommand = PropertyValue.expandAsString(optionObject["command"]!.asString()!, bindingContext: _viewModel.rootBindingContext);
                        }
                        
                        alert.addButtonWithTitle(buttonTitle);
                        buttonCommands.append(buttonCommand);
                    }
                }
            }
            else
            {
                alert.addButtonWithTitle("Close");
                buttonCommands.append(nil);
            }

            class AlertDelegate: NSObject, UIAlertViewDelegate
            {
                var _commands: [String?];
                var _onCommand: CommandHandler;
                
                init(commands: [String?], onCommand: CommandHandler)
                {
                    _commands = commands;
                    _onCommand = onCommand;
                    super.init();
                }
                
                func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int)
                {
                    if buttonIndex < _commands.count
                    {
                        if let command = _commands[buttonIndex]
                        {
                            _onCommand(command);                            
                        }
                    }
                }
            }
            
            alert.delegate = AlertDelegate(commands: buttonCommands, onCommand: onCommand);
            alert.show();
        }
    }
}
