//
//  FileManager+xattr.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 27.06.23.
//

import Foundation

struct ExtendedAttributeError: Error {
    let code: Int32
    let name: String
    let description: String

    init(errno: Int32) {
        code = errno
        switch errno {
        case EEXIST:
            name = "EEXIST"
            description = "Options contains XATTR_CREATE and the named attribute already exists."
        case ENOATTR:
            name = "ENOATTR"
            description = "GET: The extended attribute does not exist. SET: Options is set to XATTR_REPLACE and the named attribute does not exist."
        case ENOTSUP:
            name = "ENOTSUP"
            description = "The file system does not support extended attributes or has them disabled."
        case EROFS:
            name = "EROFS"
            description = "The file system is mounted read-only."
        case ERANGE:
            name = "ERANGE"
            description = "GET: Value (as indicated by size) is too small to hold the extended attribute data. SET: The data size of the attribute is out of range."
        case EPERM:
            name = "EPERM"
            description = "Attributes cannot be associated with this type of object."
        case EINVAL:
            name = "EINVAL"
            description = "Name or options is invalid."
        case EISDIR:
            name = "EISDIR"
            description = "Path or fd do not refer to a regular file and the attribute in question is only applicable to files."
        case ENOTDIR:
            name = "ENOTDIR"
            description = "A component of path is not a directory."
        case ENAMETOOLONG:
            name = "ENAMETOOLONG"
            description = "Name exceeded XATTR_MAXNAMELEN UTF-8 bytes, or a component of path exceeded NAME_MAX characters, or the entire path exceeded PATH_MAX characters."
        case EACCES:
            name = "EACCES"
            description = "Search permission is denied for a component of path or permission to set the attribute is denied."
        case ELOOP:
            name = "ELOOP"
            description = "Too many symbolic links were encountered resolving path."
        case EFAULT:
            name = "EFAULT"
            description = "Path or name points to an invalid address."
        case EIO:
            name = "EIO"
            description = "An I/O error occurred while reading from or writing to the file system."
        case E2BIG:
            name = "E2BIG"
            description = "The data size of the extended attribute is too large."
        case ENOSPC:
            name = "ENOSPC"
            description = "Not enough space left on the file system."
        default:
            name = "Unknown"
            description = "Unknown error."
        }
    }
}

extension FileManager {
    func extendedAttribute(_ name: String, on url: URL) throws -> Data {
        // Get size of attribute data
        var size = getxattr(url.path, name, nil, 0, 0, 0)
        if size == -1 {
            throw ExtendedAttributeError(errno: errno)
        }

        // Prepare buffer
        let alignment = MemoryLayout<Int8>.alignment
        let ptr = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
        defer {
            ptr.deallocate()
        }
        size = getxattr(url.path, name, ptr, size, 0, 0)

        return Data(bytes: ptr, count: size)
    }

    func setExtendedAttribute(_ name: String, on url: URL, data: Data) throws {
        try data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Void in
            guard let ptr = bytes.baseAddress else {
                return
            }
            let result = setxattr(url.path, name, ptr, data.count, 0, 0)
            if result == -1 {
                throw ExtendedAttributeError(errno: errno)
            }
        }
    }

    func removeExtendedAttribute(_ name: String, from url: URL) throws {
        let result = removexattr(url.path, name, 0)
        if result == -1 {
            // If the attribute was already gone, do nothing
            if errno != ENOATTR {
                throw ExtendedAttributeError(errno: errno)
            }
        }
    }
}
