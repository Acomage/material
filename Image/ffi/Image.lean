import Lean

-- 定义图片结构体
structure Image where
  width    : UInt32
  height   : UInt32
  channels : UInt32
  data     : ByteArray

-- 导出一个辅助函数，供 C 代码调用以创建 Image 对象。
-- 这样做的好处是 C 代码不需要知道 Image 结构体的具体内存布局。
@[export lean_create_image_obj]
def createImageObj (w h c : UInt32) (data : ByteArray) : Image :=
  { width := w, height := h, channels := c, data := data }

-- 声明外部 C 函数
-- 使用 @& String 表示借用字符串（borrowed），减少引用计数开销
@[extern "lean_load_image"]
opaque loadImage (path : @& String) : IO Image
