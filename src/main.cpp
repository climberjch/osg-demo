#include <osg/ShapeDrawable>
#include <osg/Geode>
#include <osg/MatrixTransform>
#include <osg/Group>
#include <osg/Vec4>

#include <osgGA/TrackballManipulator>
#include <osgViewer/Viewer>
#include <osgAnimation/StatsHandler>
#include "osg/ArgumentParser"

int main(int argc, char** argv)
{
    // 1. 创建一个立方体，中心在原点，边长 1.0
    osg::ref_ptr<osg::Box> box =
        new osg::Box(osg::Vec3(0.0f, 0.0f, 0.0f), 1.0f);

    // 2. 用 ShapeDrawable 包装几何体，并设置颜色
    osg::ref_ptr<osg::ShapeDrawable> shapeDrawable =
        new osg::ShapeDrawable(box.get());
    shapeDrawable->setColor(osg::Vec4(0.2f, 0.6f, 1.0f, 1.0f)); // RGBA

    // 3. Geode：几何节点
    osg::ref_ptr<osg::Geode> geode = new osg::Geode();
    geode->addDrawable(shapeDrawable.get());

    // 4. 根节点：MatrixTransform，方便以后做变换
    osg::ref_ptr<osg::MatrixTransform> root = new osg::MatrixTransform();
    root->addChild(geode.get());

    // 5. Viewer
    osgViewer::Viewer viewer;

    viewer.setSceneData(root.get());
    viewer.setUpViewOnSingleScreen();

    // 鼠标轨迹球操作器：右键旋转，中键平移，滚轮缩放
    viewer.setCameraManipulator(new osgGA::TrackballManipulator());

    // 按 S 键可以看到 FPS、三角形数等统计信息
    viewer.addEventHandler(new osgAnimation::StatsHandler());

    // 6. 进入渲染循环
    return viewer.run();
}
