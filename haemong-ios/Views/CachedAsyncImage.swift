import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var phase: AsyncImagePhase = .empty
    
    var body: some View {
        Group {
            switch phase {
            case .empty:
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            case .success(let image):
                content(image)
            case .failure:
                placeholder()
                    .onTapGesture {
                        loadImage()
                    }
            @unknown default:
                placeholder()
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else {
            phase = .failure(URLError(.badURL))
            return
        }
        
        phase = .empty
        
        // URLSession with custom configuration for better network handling
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        let session = URLSession(configuration: configuration)
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 60
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("🚫 Image download error: \(error.localizedDescription)")
                    print("🚫 Error code: \((error as NSError).code)")
                    print("🚫 Error domain: \((error as NSError).domain)")
                    
                    // 네트워크 연결 문제인 경우 자동 재시도
                    if (error as NSError).code == -1005 || (error as NSError).code == -1009 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.loadImage()
                        }
                        return
                    }
                    
                    phase = .failure(error)
                    return
                }
                
                guard let data = data, let uiImage = UIImage(data: data) else {
                    phase = .failure(URLError(.cannotDecodeContentData))
                    return
                }
                
                phase = .success(Image(uiImage: uiImage))
            }
        }.resume()
    }
}

// AsyncImagePhase implementation
enum AsyncImagePhase {
    case empty
    case success(Image)
    case failure(Error)
}