--[[
-------------------------------------------------------------------------------
      Menori
      LÖVE library for simple 3D and 2D rendering based on scene graph.
      @author rozenmad
      2023
-------------------------------------------------------------------------------
--]]
----
-- @module menori
local fPath = (...)..".modules."
---@diagnostic disable-next-line: lowercase-global
require_o = require

require = function(m)
	return require_o(fPath .. m)
end

--- Namespace for all modules in library.
-- @table menori
local menori = {
      PerspectiveCamera      = require('core3d.camera'),
      Environment            = require('core3d.environment'),
      UniformList            = require('core3d.uniform_list'),
      glTFAnimations         = require('core3d.gltf_animations'),
      glTFLoader             = require('core3d.gltf'),
      Material               = require('core3d.material'),
      BoxShape               = require('core3d.boxshape'),
      Mesh                   = require('core3d.mesh'),
      ModelNode              = require('core3d.model_node'),
      NodeTreeBuilder        = require('core3d.node_tree_builder'),
      GeometryBuffer         = require('core3d.geometry_buffer'),
      InstancedMesh          = require('core3d.instanced_mesh'),
      Camera                 = require('camera'),
      Node                   = require('node'),
      Scene                  = require('scene'),
      Sprite                 = require('sprite'),
      SpriteLoader           = require('spriteloader'),

      ShaderUtils            = require('shaders.utils'),

      app                    = require('app'),
      utils                  = require('libs.utils'),
      class                  = require('libs.class'),
      ml                     = require('ml'),

      -- deprecated
      Application            = require('deprecated.application'),
      ModelNodeTree          = require('deprecated.model_node_tree'),
}

require = require_o
---@diagnostic disable-next-line: lowercase-global, assign-type-mismatch
require_o = nil

return menori