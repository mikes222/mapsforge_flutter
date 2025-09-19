 # Known Issues & Solutions

## 🌊 Map Appears Completely Blue (Everything Looks "Under Water")

**Problem:** Your entire map is rendered in blue, making it appear as if everything is underwater.

**Root Cause:** Your map file contains areas tagged with `natural=sea`, which the rendering theme paints blue by default. However, your map is missing the complementary `natural=nosea` areas that should be rendered in light gray/white (`#F8F8F8`).

### 📖 Background
Mapsforge uses a two-layer approach for land/sea rendering:
- **Sea areas** (`natural=sea`) → Rendered in blue
- **Land areas** (`natural=nosea`) → Rendered in light gray/white

When only sea areas are present without corresponding land areas, the entire map appears blue.

### ✅ Solutions

#### **Option 1: Use Complete Land/Sea Maps** *(Recommended)*
Create or obtain map files that include both sea and land area definitions:
- ✅ **Pros:** Accurate rendering with proper land/sea distinction
- ❌ **Cons:** Slightly larger file sizes due to additional geographic data

#### **Option 2: Modify Rendering Theme** *(Quick Fix)*
If your map covers only land areas with no actual seas:

1. **Change sea color:** Edit your render theme XML file and modify the sea color:
   ```xml
   <rule e="way" k="natural" v="issea|sea">
       <area fill="#F8F8F8" />  <!-- Changed from blue to light gray -->
   </rule>
   ```

2. **Remove sea rule:** Comment out or delete the sea rendering rule entirely:
   ```xml
   <!-- <rule e="way" k="natural" v="issea|sea">
       <area fill="#B3DDFF" />
   </rule> -->
   ```

### 📚 Additional Resources
- [Mapsforge Map Creation Guide](https://github.com/mapsforge/mapsforge/blob/master/docs/MapCreation.md)
- Check your map creation tools for land/sea area generation options 
