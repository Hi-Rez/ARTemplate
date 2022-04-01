//
//  Paths.swift
//  Template
//
//  Created by Reza Ali on 8/18/21.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import Satin

public func fileExists(_ url: URL) -> Bool {
    let fm = FileManager.default
    return fm.fileExists(atPath: url.path)
}

public func removeFile(_ url: URL)
{
    let fm = FileManager.default
    if fm.fileExists(atPath: url.path)
    {
        do
        {
            try fm.removeItem(at: url)
        }
        catch
        {
            print(error)
        }
    }
}

func createDirectory(_ url: URL) -> Bool {
    let fm = FileManager.default
    do {
        try fm.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
        return true
    }
    catch {
        print(error.localizedDescription)
        return false
    }
}

public func getDocumentsDirectoryURL() -> URL
{
    #if FRAMEWORK
    return getResourcesDirectoryURL()
    #else
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    #endif
}

public func getDocumentsDirectoryURL(_ path: String) -> URL
{
    return getDocumentsDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsAssetsDirectoryURL() -> URL
{
    return getDocumentsDirectoryURL("Assets")
}

public func getDocumentsAssetsDirectoryURL(_ path: String) -> URL
{
    return getDocumentsAssetsDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsMediaDirectoryURL() -> URL
{
    return getDocumentsAssetsDirectoryURL("Media")
}

public func getDocumentsMediaDirectoryURL(_ path: String) -> URL
{
    return getDocumentsMediaDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsDataDirectoryURL() -> URL
{
    return getDocumentsAssetsDirectoryURL("Data")
}

public func getDocumentsDataDirectoryURL(_ path: String) -> URL
{
    return getDocumentsDataDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsTexturesDirectoryURL() -> URL
{
    return getDocumentsAssetsDirectoryURL("Textures")
}

public func getDocumentsTexturesDirectoryURL(_ path: String) -> URL
{
    return getDocumentsTexturesDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsParametersDirectoryURL() -> URL
{
    return getDocumentsAssetsDirectoryURL("Parameters")
}

public func getDocumentsParametersDirectoryURL(_ path: String) -> URL
{
    return getDocumentsParametersDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsModelsDirectoryURL() -> URL
{
    return getDocumentsAssetsDirectoryURL("Models")
}

public func getDocumentsModelsDirectoryURL(_ path: String) -> URL
{
    return getDocumentsModelsDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsPipelinesDirectoryURL() -> URL
{
    return getDocumentsAssetsDirectoryURL("Pipelines")
}

public func getDocumentsPipelinesDirectoryURL(_ path: String) -> URL
{
    return getDocumentsPipelinesDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsPresetsDirectoryURL() -> URL
{
    return getDocumentsAssetsDirectoryURL("Presets")
}

public func getDocumentsPresetsDirectoryURL(_ path: String) -> URL
{
    return getDocumentsPresetsDirectoryURL().appendingPathComponent(path)
}

public func getDocumentsSettingsDirectoryURL() -> URL
{
    return getDocumentsAssetsDirectoryURL("Settings")
}

public func getDocumentsSettingsDirectoryURL(_ path: String) -> URL
{
    return getDocumentsSettingsDirectoryURL().appendingPathComponent(path)
}

public func getResourcesDirectoryURL() -> URL
{
    #if FRAMEWORK
    return Bundle(for: RezanatorRenderer.self).resourceURL!
    #else
    return Bundle.main.resourceURL!
    #endif
}

public func getResourcesAssetsDirectoryURL() -> URL
{
    return getResourcesDirectoryURL("Assets")
}

public func getResourcesAssetsDirectoryURL(_ path: String) -> URL
{
    return getResourcesAssetsDirectoryURL().appendingPathComponent(path)
}

public func getResourcesDirectoryURL(_ path: String) -> URL
{
    return getResourcesDirectoryURL().appendingPathComponent(path)
}

public func getResourcesMediaDirectoryURL() -> URL
{
    return getResourcesAssetsDirectoryURL("Media")
}

public func getResourcesMediaDirectoryURL(_ path: String) -> URL
{
    return getResourcesMediaDirectoryURL().appendingPathComponent(path)
}

public func getResourcesParametersDirectoryURL() -> URL
{
    return getResourcesAssetsDirectoryURL("Parameters")
}

public func getResourcesParametersDirectoryURL(_ path: String) -> URL
{
    return getResourcesParametersDirectoryURL().appendingPathComponent(path)
}

public func getResourcesPipelinesDirectoryURL() -> URL
{
    return getResourcesAssetsDirectoryURL("Pipelines")
}

public func getResourcesPipelinesDirectoryURL(_ path: String) -> URL
{
    return getResourcesPipelinesDirectoryURL().appendingPathComponent(path)
}

public func getResourcesPresetsDirectoryURL() -> URL
{
    return getResourcesAssetsDirectoryURL("Presets")
}

public func getResourcesPresetsDirectoryURL(_ path: String) -> URL
{
    return getResourcesPresetsDirectoryURL().appendingPathComponent(path)
}

public func getResourcesSettingsDirectoryURL() -> URL
{
    return getResourcesAssetsDirectoryURL("Settings")
}

public func getResourcesModelsDirectoryURL() -> URL
{
    return getResourcesAssetsDirectoryURL("Models")
}

public func getResourcesSettingsDirectoryURL(_ path: String) -> URL
{
    return getResourcesSettingsDirectoryURL().appendingPathComponent(path)
}

public func copyResourcesModelsToDocumentsDirectory(_ force: Bool = true)
{
    copyDirectory(atPath: getResourcesModelsDirectoryURL().path, toPath: getDocumentsModelsDirectoryURL().path, force: force)
}


public func copyResourcesSettingsToDocumentsDirectory(_ force: Bool = true)
{
    copyDirectory(atPath: getResourcesSettingsDirectoryURL().path, toPath: getDocumentsSettingsDirectoryURL().path, force: force)
}

public func copyResourcesPresetsToDocumentsDirectory(_ force: Bool = true)
{
    copyDirectory(atPath: getResourcesPresetsDirectoryURL().path, toPath: getDocumentsPresetsDirectoryURL().path, force: force)
}

public func copyResourcesPipelinesToDocumentsDirectory(_ force: Bool = true)
{
    copyDirectory(atPath: getResourcesPipelinesDirectoryURL().path, toPath: getDocumentsPipelinesDirectoryURL().path, force: force)
}

public func copyResourcesParametersToDocumentsDirectory(_ force: Bool = true)
{
    copyDirectory(atPath: getResourcesParametersDirectoryURL().path, toPath: getDocumentsParametersDirectoryURL().path, force: force)
}

public func copyResourcesAssetsToDocumentsAssets(_ force: Bool = false)
{
    copyDirectory(atPath: getResourcesAssetsDirectoryURL().path, toPath: getDocumentsAssetsDirectoryURL().path, force: force)
}

func copyDirectory(atPath: String, toPath: String, force: Bool = false)
{
    let fileManager = FileManager.default
    // upon fresh install copy shaders directory
    if !fileManager.fileExists(atPath: toPath)
    {
        do
        {
            try FileManager.default.copyItem(atPath: atPath, toPath: toPath)
        }
        catch
        {
            print(error)
        }
    }
    // otherwise go through all the files and only overwrite the files that dont exist and the ones that have been updates
    else
    {
        do
        {
            let results = try fileManager.subpathsOfDirectory(atPath: atPath)
            for file in results
            {
                let srcPath = atPath + "/" + file
                let dstPath = toPath + "/" + file

                var directory = ObjCBool(false)
                if fileManager.fileExists(atPath: srcPath, isDirectory: &directory)
                {
                    if directory.boolValue
                    {
                        if !fileManager.fileExists(atPath: dstPath)
                        {
                            do
                            {
                                try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
                            }
                            catch
                            {
                                print(error)
                            }
                        }
                    }
                    else
                    {
                        do
                        {
                            let resPathAttributes = try FileManager.default.attributesOfItem(atPath: srcPath)
                            if fileManager.fileExists(atPath: dstPath)
                            {
                                let docPathAttributes = try FileManager.default.attributesOfItem(atPath: dstPath)
                                if let resDate = resPathAttributes[.modificationDate] as? Date, let docDate = docPathAttributes[.modificationDate] as? Date
                                {
                                    if force || resDate > docDate
                                    {
                                        do
                                        {
                                            try fileManager.removeItem(atPath: dstPath)
                                            try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
                                        }
                                        catch
                                        {
                                            print(error)
                                        }
                                    }
                                }
                            }
                            else
                            {
                                do
                                {
                                    try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
                                }
                                catch
                                {
                                    print(error)
                                }
                            }
                        }
                        catch
                        {
                            print(error)
                        }
                    }
                }
            }
        }
        catch
        {
            print(error)
        }
    }
}

func getPresets(_ loadUrl: URL) -> [String]
{
    let fm = FileManager.default
    var results: [String] = []
    let presetsUrl = loadUrl.appendingPathComponent("Presets")
    if fm.fileExists(atPath: presetsUrl.path)
    {
        do
        {
            let presets = try fm.contentsOfDirectory(atPath: presetsUrl.path)
            for preset in presets
            {
                let presetUrl = presetsUrl.appendingPathComponent(preset)
                var isDirectory: ObjCBool = false
                if fm.fileExists(atPath: presetUrl.path, isDirectory: &isDirectory)
                {
                    if isDirectory.boolValue
                    {
                        results.append(preset)
                    }
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    results.sort()
    return results
}
