////
////  MetalRenderer.swift
////  FaceDetectionApp
////
////  Created by Amy Huang on 1/18/25.
////
//
//import Metal
//import MetalKit
//
//class MetalRenderer {
//    private let device: MTLDevice
//    private let commandQueue: MTLCommandQueue
//    private let renderPipelineState: MTLRenderPipelineState
//    
//    init?(mtkView: MTKView) {
//        guard let device = MTLCreateSystemDefaultDevice(),
//              let queue = device.makeCommandQueue() else {
//            return nil
//        }
//        self.device = device
//        self.commandQueue = queue
//        
//        // Configure pipeline
//        do {
//            let pipelineDescriptor = MTLRenderPipelineDescriptor()
//            pipelineDescriptor.vertexFunction = MetalRenderer .defaultLibrary?.makeFunction(name: "vertex_main")
//            pipelineDescriptor.fragmentFunction = MetalRenderer.defaultLibrary?.makeFunction(name: "fragment_main")
//            pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
//            
//            self.renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
//        } catch {
//            print("Failed to create pipeline state: \(error)")
//            return nil
//        }
//        
//        mtkView.device = device
//    }
//    
//    func draw(rectangles: [CGRect], in view: MTKView) {
//        guard let drawable = view.currentDrawable,
//              let renderPassDescriptor = view.currentRenderPassDescriptor else {
//            return
//        }
//        
//        let commandBuffer = commandQueue.makeCommandBuffer()!
//        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
//        
//        renderEncoder.setRenderPipelineState(renderPipelineState)
//        
//        // Prepare data for rectangles
//        let vertices = MetalRenderer.generateVertices(for: rectangles)
//        let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
//        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count / 2)
//        
//        renderEncoder.endEncoding()
//        commandBuffer.present(drawable)
//        commandBuffer.commit()
//    }
//    
//    private static func generateVertices(for rectangles: [CGRect]) -> [Float] {
//        var vertices = [Float]()
//        for rect in rectangles {
//            let x = Float(rect.origin.x)
//            let y = Float(rect.origin.y)
//            let width = Float(rect.size.width)
//            let height = Float(rect.size.height)
//            
//            // Define vertices for two triangles forming a rectangle
//            vertices += [
//                x, y,
//                x + width, y,
//                x, y + height,
//                
//                x, y + height,
//                x + width, y,
//                x + width, y + height
//            ]
//        }
//        return vertices
//    }
//}
