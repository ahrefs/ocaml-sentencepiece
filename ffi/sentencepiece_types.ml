open Ctypes

module Types (F : Ctypes.TYPE) = struct
  open F

  type processor

  let processor : processor structure ptr typ = ptr (structure "sp_processor_t")
  let status = typedef int "sp_status_t"
end
