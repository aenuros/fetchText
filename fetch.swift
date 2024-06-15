import SwiftUI
import UIKit
import Vision
import Photos
import Foundation

struct IdentifiableImage: Identifiable {
    var id = UUID()
    var image: UIImage
    var name: String
    var date: Date
}


    func createTxt(title: String, _ text: String) {
        let url = URL( fileURLWithPath: "/Users/name/\(title).txt" )

        // write:
        do {
          try text.write(to: url, atomically: true, encoding: .utf8)
        }
        catch {
          print("Error writing: \(error.localizedDescription)")
        }

        // read:
        do {
          let s = try String( contentsOf: url )
          print(s)
        }
        catch {
          print("Error thrown while reading file. \(error.localizedDescription)")
        }
    }
    
    func getall(_ labels: [IdentifiableImage]) {
        var text: [String] = []
        var currentLabelIndex = 0

        func analyze(img: UIImage, completion: @escaping () -> Void) {
            loading = true
            DispatchQueue.global().async {
                // Get the CGImage on which to perform requests.
                guard let cgImage = img.cgImage else {
                    loading = false
                    completion()
                    return
                }

                // Create a new image-request handler.
                let requestHandler = VNImageRequestHandler(cgImage: cgImage)

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

            loading = false
        }

        func processResults2(strings: [String]) {
            for string1 in strings {
                text.append(string1)
            }
        }

        func analyzeNext() {
            if currentLabelIndex < labels.count {
                let label = labels[currentLabelIndex]
                analyze(img: label.image) {
                    currentLabelIndex += 1
                    analyzeNext()
                }
            } else {
                print("All analyses completed")
                createTxt(title: "test3", text.joined(separator: " \n"))
            }
        }

        analyzeNext()
    }
        
    func loadPNGsFromDirectory(directoryPath: String) -> [UIImage] {
        var images = [UIImage]()
        
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: directoryPath), includingPropertiesForKeys: nil)
            
            for url in fileURLs {
                if url.pathExtension.lowercased() == "png" {
                    if let image = UIImage(contentsOfFile: url.path), let date = fileModificationDate(url: url) {
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
        // Example usage
        let directoryPath = "/Users/name/Documents/unfairtest"
        _ = loadPNGsFromDirectory(directoryPath: directoryPath)
        
        // Print the number of images loaded
        print("Loaded \(identifiables.count) PNG images.")
        
        identifiables.sort {
            $0.date < $1.date
        }
        
        for identifiable in identifiables {
            print(identifiable.name)
        }
        
        getall(identifiables)
    }
