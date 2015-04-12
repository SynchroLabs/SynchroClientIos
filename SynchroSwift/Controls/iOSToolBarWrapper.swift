//
//  iOSToolBarWrapper.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/13/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation
import UIKit

private var logger = Logger.getLogger("iOSToolBarWrapper");

private var commands = [CommandName.OnClick.Attribute];

public class iOSToolBarWrapper : iOSControlWrapper
{
    class func systemItemFromName(name: String?) -> UIBarButtonSystemItem?
    {
        if name != nil
        {
            switch name!
            {
                case "Action":
                    return UIBarButtonSystemItem.Action;
                case "Add":
                    return UIBarButtonSystemItem.Add;
                case "Bookmarks":
                    return UIBarButtonSystemItem.Bookmarks;
                case "Camera":
                    return UIBarButtonSystemItem.Camera;
                case "Cancel":
                    return UIBarButtonSystemItem.Cancel;
                case "Compose":
                    return UIBarButtonSystemItem.Compose;
                case "Done":
                    return UIBarButtonSystemItem.Done;
                case "Edit":
                    return UIBarButtonSystemItem.Edit;
                case "FastForward":
                    return UIBarButtonSystemItem.FastForward;
                case "FixedSpace":
                    return UIBarButtonSystemItem.FixedSpace;
                case "FlexibleSpace":
                    return UIBarButtonSystemItem.FlexibleSpace;
                case "Organize":
                    return UIBarButtonSystemItem.Organize;
                case "PageCurl":
                    return UIBarButtonSystemItem.PageCurl;
                case "Pause":
                    return UIBarButtonSystemItem.Pause;
                case "Play":
                    return UIBarButtonSystemItem.Play;
                case "Redo":
                    return UIBarButtonSystemItem.Redo;
                case "Refresh":
                    return UIBarButtonSystemItem.Refresh;
                case "Reply":
                    return UIBarButtonSystemItem.Reply;
                case "Rewind":
                    return UIBarButtonSystemItem.Rewind;
                case "Save":
                    return UIBarButtonSystemItem.Save;
                case "Search":
                    return UIBarButtonSystemItem.Search;
                case "Stop":
                    return UIBarButtonSystemItem.Stop;
                case "Trash":
                    return UIBarButtonSystemItem.Trash;
                case "Undo":
                    return UIBarButtonSystemItem.Undo;
                default: ()
            }
        }
        
        return nil;
    }
    
    public class func loadIconImage(named: String) -> UIImage?
    {
        return UIImage(named: "Res/icons/blue/" + named);
    }
    
    public init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating toolbar element");
        super.init(parent: parent, bindingContext: bindingContext);
        
        var buttonItem: UIBarButtonItem!;
        
        // Note: Because the navBar button does not coerce/stlye images, it is recommended that you use either a systemItem or text-only
        //       button element on the navBar (especially important for correct styling across different versions of iOS).
        //
        
        if let systemItemName = controlSpec["systemItem"]?.asString()
        {
            // System items:
            //
            //     Done, Cancel, Edit, Save, Add, Compose, Reply, Action, Organize, Bookmarks, Search, Refresh, Stop,
            //     Camera, Trash, Play, Pause, Rewind, FastForward, Undo, Redo, PageCurl
            //
            //     https://developer.apple.com/library/ios/documentation/uikit/reference/UIBarButtonItem_Class/Reference/Reference.html
            //
            if let systemItem = iOSToolBarWrapper.systemItemFromName(systemItemName)
            {
                buttonItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: "barButtonItemClicked:")
            }
            else
            {
                assert(false, "Specified invalid system button value: \"\(systemItemName)\"");
            }
        }
        else
        {
            // Custom items, can specify text, icon, or both
            //
            buttonItem = UIBarButtonItem(image: nil, style: .Plain, target: self, action: "barButtonItemClicked:")
            processElementProperty(controlSpec["text"], setValue: { (value) in buttonItem.title = self.toString(value) });
            processElementProperty(controlSpec["icon"], setValue: { (value) in buttonItem.image = iOSToolBarWrapper.loadIconImage(self.toString(value)) });
        }
        
        processElementProperty(controlSpec["enabled"], setValue: { (value) in buttonItem.enabled = self.toBoolean(value) });
        
        if (controlSpec["control"]?.asString() == "navBar.button")
        {
            // When image and text specified, uses image.  Image is placed on button surface verbatim (no color coersion).
            //
            _pageView.setNavBarButton(buttonItem);
        }
        else // toolBar.button
        {
            // Can use image, text, or both, and toolbar shows what was provided (including image+text).  Toolbar coerces colors
            // and handles disabled state (for example, on iOS 6, icons/text show up as white when enabled and gray when disabled).
            //
            _pageView.addToolbarButton(buttonItem);
        }
        
        _isVisualElement = false;
        
        if let bindingSpec = BindingHelper.getCanonicalBindingSpec(controlSpec, defaultBindingAttribute: CommandName.OnClick.Attribute, commandAttributes: commands)
        {
            processCommands(bindingSpec, commands: commands);
        }
    }
    
    func barButtonItemClicked(barButtonItem: UIBarButtonItem)
    {
        if let command = getCommand(CommandName.OnClick)
        {
            logger.debug("Button click with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(bindingContext));
        }
    }
}
