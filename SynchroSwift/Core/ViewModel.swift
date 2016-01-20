//
//  ViewModel.swift
//  SynchroSwift
//
//  Created by Robert Dickinson on 12/6/14.
//  Copyright (c) 2014 Robert Dickinson. All rights reserved.
//

import Foundation

private var logger = Logger.getLogger("ViewModel");

// The ViewModel will manage the client view model data (initialize and update it).  It will also manage all bindings
// to view model data, including managing updates on changes.
//
public class ViewModel
{
    var _rootBindingContext: BindingContext;
    var _rootObject = JObject();
    var _updatingView = false;
    
    var _valueBindings = [ValueBinding]();
    var _propertyBindings = [PropertyBinding]();
    
    public init()
    {
        _rootBindingContext = BindingContext(_rootObject);
    }
    
    public var rootBindingContext: BindingContext { get { return _rootBindingContext; } }
    
    public var rootObject: JObject { get { return _rootObject; } } // Only used by BindingContext - "internal"?
    
    public func createAndRegisterValueBinding(bindingContext: BindingContext, getValue: GetViewValue, setValue: SetViewValue?) -> ValueBinding
    {
        let valueBinding = ValueBinding(viewModel: self, bindingContext: bindingContext, getViewValue: getValue, setViewValue: setValue);
        _valueBindings.append(valueBinding);
        return valueBinding;
    }
    
    public func unregisterValueBinding(valueBinding: ValueBinding)
    {
        _valueBindings.removeObject(valueBinding);
    }
    
    public func createAndRegisterPropertyBinding(bindingContext: BindingContext, value: String, setValue: SetViewValue?) -> PropertyBinding
    {
        let propertyBinding = PropertyBinding(bindingContext: bindingContext, value: value, setViewValue: setValue);
        _propertyBindings.append(propertyBinding);
        return propertyBinding;
    }
    
    public func unregisterPropertyBinding(propertyBinding: PropertyBinding)
    {
        _propertyBindings.removeObject(propertyBinding);
    }
    
    // Tokens in the view model have a "ViewModel." prefix (as the view model itself is a child node of a larger
    // JSON response).  We need to prune that off so future SelectToken operations will work when applied to the
    // root binding context (the context associated with the "ViewModel" JSON object).
    //
    public class func getTokenPath(token: JToken) -> String
    {
        var path = token.Path;
    
        if (path.hasPrefix("ViewModel."))
        {
            path = path.substring("ViewModel.".characters.count);
        }
    
        return path;
    }
    
    public func initializeViewModelData(viewModel: JObject)
    {
        _rootObject = viewModel;
        _rootBindingContext = BindingContext(_rootObject);
        
        // Clear bindings
        _valueBindings.removeAll();
        _propertyBindings.removeAll();
    }
    
    public func setViewModelData(viewModel: JObject)
    {
        _rootObject = viewModel;
        _rootBindingContext = BindingContext(_rootObject);
        
        // Update Bindings (setting BindingRoot to new value will cause rebind)
        //
        for valueBinding in _valueBindings
        {
            valueBinding.bindingContext.BindingRoot = _rootBindingContext.BindingRoot;
        }
        for propertyBinding in _propertyBindings
        {
            for propBinding in propertyBinding.BindingContexts
            {
                propBinding.BindingRoot = _rootBindingContext.BindingRoot;
            }
        }
    }
    
    // This object represents a binding update (the path of the bound item and an indication of whether rebinding is required)
    //
    public class BindingUpdate
    {
        public var bindingPath: String;
        public var rebindRequired: Bool;
        
        public init(bindingPath: String, rebindRequired: Bool)
        {
            self.bindingPath = bindingPath;
            self.rebindRequired = rebindRequired;
        }
    }
    
    // If bindingUpdates is provided, any binding other than an optionally specified sourceBinding
    // that is impacted by a token in bindingUpdates will have its view updated.  If no bindingUpdates
    // is provided, all bindings will have their view updated.
    //
    // If bindingUpdates is provided, any binding impacted by a path for which rebinding is indicated
    // will be rebound.
    //
    // Usages:
    //    On new view model - no params - update view for all bindings, no rebind needed
    //    On update view model - pass list containing all updates
    //    On update view (from ux) - pass list containing the single update, and the sourceBinding (that triggered the update)
    //
    public func updateViewFromViewModel(bindingUpdates: [BindingUpdate]? = nil, sourceBinding: BindingContext? = nil)
    {
        _updatingView = true;
    
        for valueBinding in _valueBindings
        {
            if (valueBinding.bindingContext !== sourceBinding)
            {
                var isUpdateRequired = (bindingUpdates == nil);
                var isBindingDirty = false;
                if (bindingUpdates != nil)
                {
                    for bindingUpdate in bindingUpdates!
                    {
                        if (valueBinding.bindingContext.isBindingUpdated(bindingUpdate.bindingPath, objectChange: bindingUpdate.rebindRequired))
                        {
                            isUpdateRequired = true;
                            if (bindingUpdate.rebindRequired)
                            {
                                isBindingDirty = true;
                                break;
                            }
                        }
                    }
                }
    
                if (isBindingDirty)
                {
                    logger.debug("Rebind value binding with path: \(valueBinding.bindingContext.BindingPath)");
                    valueBinding.bindingContext.rebind();
                }
    
                if (isUpdateRequired)
                {
                    valueBinding.updateViewFromViewModel();
                }
            }
        }
    
        for propertyBinding in _propertyBindings
        {
            var isUpdateRequired = (bindingUpdates == nil);
    
            for propBinding in propertyBinding.BindingContexts
            {
                var isBindingDirty = false;
                if (bindingUpdates != nil)
                {
                    for bindingUpdate in bindingUpdates!
                    {
                        if (propBinding.isBindingUpdated(bindingUpdate.bindingPath, objectChange: bindingUpdate.rebindRequired))
                        {
                            isUpdateRequired = true;
                            if (bindingUpdate.rebindRequired)
                            {
                                isBindingDirty = true;
                                break;
                            }
                        }
                    }
                }
    
                if (isBindingDirty)
                {
                    logger.debug("Rebind property binding with path: \(propBinding.BindingPath)");
                    propBinding.rebind();
                }
            }
    
            if (isUpdateRequired)
            {
                propertyBinding.updateViewFromViewModel();
            }
        }
    
        _updatingView = false;
    }
    
    public func updateViewModelData(viewModelDeltas: JToken, updateView: Bool = true)
    {
        var bindingUpdates = [BindingUpdate]();
    
        logger.debug("Processing view model updates: \(viewModelDeltas)");
        if (viewModelDeltas.Type == JTokenType.Array)
        {
            // Removals are generally reported as removals from the end of the list with increasing indexes.  If
            // we process them in this way, the first removal will change the list positions of remaining items
            // and cause subsequent removals to be off (typically to fail).  And we don't really want to rely
            // on ordering in the first place.  So what we are going to do is track all of the removals, and then
            // actually remove them at the end.
            //
            var removals = [JToken]();
    
            for element in viewModelDeltas as! JArray
            {
                let viewModelDelta = element as! JObject;
                let path = (viewModelDelta as JObject)["path"]!.asString()!;
                let value = viewModelDelta["value"]?.deepClone();
                let changeType = (viewModelDelta as JObject)["change"]!.asString()!;
    
                logger.debug("View model item change (\(changeType)) for path: {\(path)}");
                if (changeType == "object")
                {
                    // For "object" changes, this just means that an existing object had a property added/updated/removed or
                    // an array had items added/updated/removed.  We don't need to actually do any updates for this notification,
                    // we just need to make sure any bound elements get their views updated appropriately.
                    //
                    bindingUpdates.append(BindingUpdate(bindingPath: path, rebindRequired: false));
                }
                else if (changeType == "update")
                {
                    if (value != nil)
                    {
                        var vmItemValue = _rootObject.selectToken(path);
                        if (vmItemValue != nil)
                        {
                            logger.debug("Updating view model item for path: \(path) to value: \(value!)");
        
                            let rebindRequired = JToken.updateTokenValue(&vmItemValue!, newToken: value!);
                            bindingUpdates.append(BindingUpdate(bindingPath: path, rebindRequired: rebindRequired));
                        }
                        else
                        {
                            logger.error("VIEW MODEL SYNC WARNING: Unable to find existing value when processing update, something went wrong, path: \(path)");
                        }
                    }
                    else
                    {
                        logger.error("VIEW MODEL SYNC WARNING: Update change had no 'value' attribute, path: \(path)");
                    }
                }
                else if (changeType == "add")
                {
                    logger.debug("Adding bound item for path:\(path) with value: \(value)");
                    bindingUpdates.append(BindingUpdate(bindingPath: path, rebindRequired: true));

                    if (value != nil)
                    {
                        // First, double check to make sure the path doesn't actually exist
                        let vmItemValue = _rootObject.selectToken(path, errorWhenNoMatch: false);
                        if (vmItemValue == nil)
                        {
                            if (path.hasSuffix("]"))
                            {
                                // This is an array element...
                                let parenPos = path.lastIndexOf("[");
                                let parentPath = path.substringToIndex(parenPos!);
                                let parentToken = _rootObject.selectToken(parentPath);
                                if ((parentToken != nil) && (parentToken is JArray))
                                {
                                    (parentToken as! JArray).append(value!);
                                }
                                else
                                {
                                    logger.error("VIEW MODEL SYNC WARNING: Attempt to add array member, but parent didn't exist or was not an array, parent path: \(parentPath)");
                                }
                            }
                            else if (path.contains("."))
                            {
                                // This is an object property...
                                let dotPos = path.lastIndexOf(".");
                                let parentPath = path.substringToIndex(dotPos!);
                                let attributeName = path.substringFromIndex((dotPos!).advancedBy(1));
                                let parentToken = _rootObject.selectToken(parentPath);
                                if ((parentToken != nil) && (parentToken is JObject))
                                {
                                    (parentToken as! JObject)[attributeName] = value;
                                }
                                else
                                {
                                    logger.error("VIEW MODEL SYNC WARNING: Attempt to add object property, but parent didn't exist or was not an object, parent path: \(parentPath)");
                                }
                            }
                            else
                            {
                                // This is a root property...
                                _rootObject[path] = value;
                            }
                        }
                        else
                        {
                            logger.error("VIEW MODEL SYNC WARNING: Add change had no 'value' attribute, path: \(path)");
                        }
                    }
                    else
                    {
                        logger.error("VIEW MODEL SYNC WARNING: Found existing value when processing add, something went wrong, path: \(path)");
                    }
                }
                else if (changeType == "remove")
                {
                    logger.debug("Removing bound item for path: \(path)");
                    bindingUpdates.append(BindingUpdate(bindingPath: path, rebindRequired: true));
    
                    let vmItemValue = _rootObject.selectToken(path);
                    if (vmItemValue != nil)
                    {
                        logger.debug("Removing bound item for path: \(vmItemValue!.Path)");
                        // Just track this removal for now - we'll remove it at the end
                        removals.append(vmItemValue!);
                    }
                    else
                    {
                        logger.error("VIEW MODEL SYNC WARNING: Attempt to remove object property or array element, but it wasn't found, path: \(path)");
                    }
                }
            }
    
            // Remove all tokens indicated as removed
            for vmItemValue in removals
            {
                vmItemValue.remove();
            }
    
            logger.debug("View model after processing updates: \(_rootObject)");
        }
    
        if (updateView)
        {
            updateViewFromViewModel(bindingUpdates);
        }
    }
    
    // This is called when a value change is triggered from the UX, specifically when the control calls
    // the UpdateValue member of it's ValueBinding.  We will change the value, record the change, and
    // update any binding that depends on this value.  This is the mechanism that allows for "client side
    // dynamic binding".
    //
    public func updateViewModelFromView(bindingContext: BindingContext, getValue: GetViewValue)
    {
        if (_updatingView)
        {
            // When we update the view from the view model, the UX generates a variety of events to indicate
            // that values changed (text changed, list contents changed, selection changed, etc).  We don't
            // want those events to trigger a view model update (and mark as dirty), so we bail here.  This
            // check is not sufficient (by itself), since some of these events can be posted and will show up
            // asynchronously, so we do some other checks, but this is quick and easy and catches most of it.
            //
            return;
        }
    
        let newValue = getValue();
        let currentValue = bindingContext.getValue();
        if (newValue == currentValue)
        {
            // Only record changes and update dependant UX objects for actual value changes - some programmatic
            // changes to set the view to the view model state will trigger otherwise unidentifiable change events,
            // and this check will weed those out (if they got by the _updatingView check above).
            //
            return;
        }
    
        // Update the view model
        //
        let rebindRequired = bindingContext.setValue(newValue);
    
        // Find the ValueBinding that triggered this update and mark it as dirty...
        //
        for valueBinding in _valueBindings
        {
            if (valueBinding.bindingContext === bindingContext)
            {
                // logger.debug("Marking dirty - binding with path: \(bindingContext.BindingPath)");
                valueBinding.isDirty = true;
            }
        }
    
        // Process all of the rest of the bindings (rebind and update view as needed)...
        //
        var bindingUpdates = [BindingUpdate]();
        bindingUpdates.append(BindingUpdate(bindingPath: bindingContext.BindingPath, rebindRequired: rebindRequired));
        updateViewFromViewModel(bindingUpdates, sourceBinding: bindingContext);
    }
    
    public func isDirty() -> Bool
    {
        for valueBinding in _valueBindings
        {
            if (valueBinding.isDirty)
            {
                return true;
            }
        }
        return false;
    }
    
    public func collectChangedValues() -> Dictionary<String, JToken>
    {
        var vmDeltas = Dictionary<String, JToken>();
    
        for valueBinding in _valueBindings
        {
            if (valueBinding.isDirty)
            {
                let path = valueBinding.bindingContext.BindingPath;
                let value: JToken = valueBinding.bindingContext.getValue()!;
                logger.debug("Changed view model item - path: \(path) - value: \(value)");
                vmDeltas[path] = value;
                valueBinding.isDirty = false;
            }
        }
    
        return vmDeltas;
    }
}
