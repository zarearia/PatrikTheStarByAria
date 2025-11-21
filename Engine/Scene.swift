//
//  Scene.swift
//  PatrikTheStarByAria
//
//  Created by Aria Zare on 20/11/2025.
//

import MetalKit

class Scene {
    var size: CGSize
    
    var cameras: [Camera] = [Camera()]
    var currentCameraIndex: Int = 0
    var camera: Camera {
        cameras[currentCameraIndex]
    }
    
    //TODO: Lights also need to be handled in child scene
    var lights: [Light] = []
    
    // not every node is going to be a renderable
    var rootNode = Node()
    var renderables: [Renderable] = []
    
    
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()

    init(size: CGSize) {
        self.size = size
        setupScene()
        sceneSizeWillChange(newSize: size)
        
        //TODO: handle lights properly later
        var sunLight = Light()
        sunLight.color = float3(1, 1, 1)
        sunLight.position = float3(1, 2, -2)
        sunLight.intensity = 1
        sunLight.type = SunLight
        sunLight.specularColor = float3(1, 1, 1)
        lights.append(sunLight)
    }
    
    func setupScene() {
        //should be overwritten
    }
    
    func sceneSizeWillChange(newSize: CGSize) {
        let aspect: Float = Float(newSize.width / newSize.height)
        cameras = cameras.map {
            $0.aspect = aspect
            return $0
        }
        uniforms.projectionMatrix = camera.projectionMatrix
    }
    
    func update(deltaTime: Float) {
        uniforms.viewMatrix = camera.viewMatrix
        fragmentUniforms.cameraPosition = camera.position

        updateScene(deltaTime: deltaTime)
//        updateNodes(nodes: rootNode.children, deltaTime: deltaTime)
    }
    
    //TODO: Do we need this? because I'm updating all the renderables in the Model class
//    func updateNodes(nodes: [Node], deltaTime: Float) {
//        for node in nodes {
//            node.update(deltaTime: deltaTime)
//            updateNodes(nodes: node.children, deltaTime: deltaTime)
//        }
//    }
    
    func updateScene(deltaTime: Float) {
        //override this
    }
    
    func add(node: Node, parent: Node? = nil) {
        
        if let renderable = node as? Renderable {
            renderables.append(renderable)
        }
        
        guard let parent else {
            rootNode.addChild(node: node)
            return
        }
        parent.addChild(node: node)
    }
    
    //TODO: add remove func for nodes
    func remove(node: inout Node) {
        if let renderable = node as? Renderable {
            renderables.removeAll { $0 as? Node === node }
        }
        
        if let parent = node.parent {
            parent.removeChild(child: node)
        }
        
        //TODO: checl to see if we won't have memory leak here
        for child in node.children {
            child.parent = nil
        }
        node.children = []
    }
}
