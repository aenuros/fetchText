
import SwiftUI
import Vision
import Photos
import Foundation
import class Vision.VNRecognizeTextRequest

struct IdentifiableImage: Identifiable {
    var id = UUID()
    var image: CGImage
    var name: String
    var date: Date
}

guard CommandLine.argc == 3 else {
    print("Usage: MyCommandLineTool <directory_path> <file_name>")
    exit(1)
}

let arguments = CommandLine.arguments
let directoryPath = arguments[1]
let fileName = arguments[2]

var isDir: ObjCBool = false
let fileManager = FileManager.default

guard fileManager.fileExists(atPath: directoryPath, isDirectory: &isDir), isDir.boolValue else {
    print("Error: Directory does not exist at path \(directoryPath)")
    exit(1)
}

func createTxt(_ text: String) {
    let url = URL( fileURLWithPath: "/Users/name/Documents/output/\(fileName).txt" )

    do {
      try text.write(to: url, atomically: true, encoding: .utf8)
    }
    catch {
      print("Error writing: \(error.localizedDescription)")
    }

    do {
      let s = try String( contentsOf: url )
      print(s)
    }
    catch {
      print("Error thrown while reading file. \(error.localizedDescription)")
    }
}

var loading = false
var identifiables: [IdentifiableImage] = []

func getall(_ labels: [IdentifiableImage]) {
    var text: [String] = []
    var currentLabelIndex = 0

    func analyze(img: CGImage, completion: @escaping () -> Void) {
        loading = true
        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: img)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest { request, error in
            recognizeTextHandler2(request: request, error: error)
            completion()
        }

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            loading = false
            completion()
        }
    }

    func recognizeTextHandler2(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            observation.topCandidates(1).first?.string
        }

        processResults2(strings: recognizedStrings)
        print("recognized", recognizedStrings)
        loading = false
    }

    func processResults2(strings: [String]) {
        for string1 in strings {
            text.append(string1)
        }
    }

    func analyzeNext() {
        print("doing \(currentLabelIndex)/\(identifiables.count)")
        if currentLabelIndex < labels.count {
            let label = labels[currentLabelIndex]
            analyze(img: label.image) {
                currentLabelIndex += 1
                analyzeNext()
            }
        } else {
            print("All analyses completed")
            createTxt(text.joined(separator: " \n"))
        }
    }

    analyzeNext()
}

func loadPNGImage(from filePath: String) -> CGImage? {
    guard let dataProvider = CGDataProvider(filename: filePath),
          let cgImage = CGImage(pngDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
        return nil
    }
    return cgImage
}

func loadPNGsFromDirectory(directoryPath: String) -> [CGImage] {
    var images = [CGImage]()
    
    // Get the file URLs from the directory
    let fileManager = FileManager.default
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: directoryPath), includingPropertiesForKeys: nil)
        
        // Filter PNG files and create UIImage objects
        for url in fileURLs {
            if url.pathExtension.lowercased() == "png" {
                if let image = loadPNGImage(from: url.path), let date = fileModificationDate(url: url) {
                        identifiables.append(IdentifiableImage(image: image, name: url.path, date: date))
                        images.append(image)
                }
            }
        }
    } catch {
        print("Error while enumerating files \(directoryPath): \(error.localizedDescription)")
    }
    
    return images
}

func fileModificationDate(url: URL) -> Date? {
    do {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        return attr[FileAttributeKey.modificationDate] as? Date
    } catch {
        return Date(timeIntervalSinceReferenceDate: -123456789.0)
    }
}

func openUnfairTest() {
    _ = loadPNGsFromDirectory(directoryPath: directoryPath)
    
    // Print the number of images loaded
    print("Loaded \(identifiables.count) PNG images.")
    
    identifiables.sort {
        $0.date < $1.date
    }
    
    for identifiable in identifiables {
        print(identifiable.name)
    }
    print("Total count: ", identifiables.count)
    getall(identifiables)
}
openUnfairTest()
