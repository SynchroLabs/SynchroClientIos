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

open class iOSToolBarWrapper : iOSControlWrapper
{
    class func systemItemFromName(_ name: String?) -> UIBarButtonSystemItem?
    {
        if name != nil
        {
            switch name!
            {
                case "Action":
                    return UIBarButtonSystemItem.action;
                case "Add":
                    return UIBarButtonSystemItem.add;
                case "Bookmarks":
                    return UIBarButtonSystemItem.bookmarks;
                case "Camera":
                    return UIBarButtonSystemItem.camera;
                case "Cancel":
                    return UIBarButtonSystemItem.cancel;
                case "Compose":
                    return UIBarButtonSystemItem.compose;
                case "Done":
                    return UIBarButtonSystemItem.done;
                case "Edit":
                    return UIBarButtonSystemItem.edit;
                case "FastForward":
                    return UIBarButtonSystemItem.fastForward;
                case "FixedSpace":
                    return UIBarButtonSystemItem.fixedSpace;
                case "FlexibleSpace":
                    return UIBarButtonSystemItem.flexibleSpace;
                case "Organize":
                    return UIBarButtonSystemItem.organize;
                case "PageCurl":
                    return UIBarButtonSystemItem.pageCurl;
                case "Pause":
                    return UIBarButtonSystemItem.pause;
                case "Play":
                    return UIBarButtonSystemItem.play;
                case "Redo":
                    return UIBarButtonSystemItem.redo;
                case "Refresh":
                    return UIBarButtonSystemItem.refresh;
                case "Reply":
                    return UIBarButtonSystemItem.reply;
                case "Rewind":
                    return UIBarButtonSystemItem.rewind;
                case "Save":
                    return UIBarButtonSystemItem.save;
                case "Search":
                    return UIBarButtonSystemItem.search;
                case "Stop":
                    return UIBarButtonSystemItem.stop;
                case "Trash":
                    return UIBarButtonSystemItem.trash;
                case "Undo":
                    return UIBarButtonSystemItem.undo;
                default: ()
            }
        }
        
        return nil;
    }
    
    public override init(parent: ControlWrapper, bindingContext: BindingContext, controlSpec:  JObject)
    {
        logger.debug("Creating toolbar element");
        super.init(parent: parent, bindingContext: bindingContext, controlSpec: controlSpec);
        
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
                buttonItem = UIBarButtonItem(barButtonSystemItem: systemItem, target: self, action: #selector(barButtonItemClicked))
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
            buttonItem = UIBarButtonItem(image: nil, style: .plain, target: self, action: #selector(barButtonItemClicked))
            processElementProperty(controlSpec, attributeName: "text", setValue: { (value) in buttonItem.title = self.toString(value) });
            processElementProperty(controlSpec, attributeName: "icon", setValue: { (value) in buttonItem.image = iOSControlWrapper.loadImageFromIcon(self.toString(value)) });
        }
        
        processElementProperty(controlSpec, attributeName: "enabled", setValue: { (value) in buttonItem.isEnabled = self.toBoolean(value) });
        
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
    
    func barButtonItemClicked(_ barButtonItem: UIBarButtonItem)
    {
        if let command = getCommand(CommandName.OnClick)
        {
            logger.debug("Button click with command: \(command)");
            self.stateManager.sendCommandRequestAsync(command.Command, parameters: command.getResolvedParameters(bindingContext));
        }
    }
}
