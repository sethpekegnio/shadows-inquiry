extends Node

class_name SceneManager

signal scene_changed(scene_path: String)
signal scene_load_failed(error: int)

var current_scene: Node = null
var is_changing_scene: bool = false

func change_scene_safely(scene_path: String) -> void:
    if is_changing_scene:
        push_warning("Scene change already in progress")
        return
        
    is_changing_scene = true
    print("🔄 Starting safe scene transition to: " + scene_path)
    
    if not ResourceLoader.exists(scene_path):
        push_error("❌ Scene does not exist: " + scene_path)
        scene_load_failed.emit(ERR_FILE_NOT_FOUND)
        is_changing_scene = false
        return
        
    # Cleanup current scene
    if current_scene:
        current_scene.queue_free()
        await current_scene.tree_exited
    
    # Small delay to ensure cleanup
    await get_tree().create_timer(0.1).timeout
    
    # Load new scene
    var result = get_tree().change_scene_to_file(scene_path)
    if result != OK:
        push_error("❌ Failed to load scene: " + str(result))
        scene_load_failed.emit(result)
    else:
        current_scene = get_tree().current_scene
        print("✓ Scene loaded successfully: " + scene_path)
        scene_changed.emit(scene_path)
    
    is_changing_scene = false

func cleanup_resources() -> void:
    # Cleanup RayCasts
    for node in get_tree().get_nodes_in_group("cleanup_required"):
        if is_instance_valid(node):
            node.queue_free()
    
    # Force garbage collection
    ResourceLoader.load_threaded_get_status("dummy_path")
