#include <QApplication>
#include <QMainWindow>
#include <QOpenGLWidget>
#include <QVBoxLayout>
#include <QLabel>
#include <QTimer>
#include <QKeyEvent>
#include <QElapsedTimer>

#include <osg/Group>
#include <osg/Geode>
#include <osg/ShapeDrawable>
#include <osg/MatrixTransform>
#include <osg/PositionAttitudeTransform>
#include <osg/StateSet>

#include <osgGA/TrackballManipulator>
#include <osgGA/EventQueue>

#include <osgViewer/Viewer>
#include <osgViewer/GraphicsWindow>
#include <osgViewer/ViewerEventHandlers>

static osg::ref_ptr<osg::Node> createTestGeometry()
{
    auto root = new osg::Group();

    // 一个 Geode + ShapeDrawable（Box + Sphere）
    auto geode = new osg::Geode();
    geode->addDrawable(new osg::ShapeDrawable(new osg::Box(osg::Vec3(-1.0f, 0.0f, 0.0f), 1.0f)));
    geode->addDrawable(new osg::ShapeDrawable(new osg::Sphere(osg::Vec3(+1.0f, 0.0f, 0.0f), 0.6f)));

    // 简单材质：开深度测试
    geode->getOrCreateStateSet()->setMode(GL_DEPTH_TEST, osg::StateAttribute::ON);

    root->addChild(geode);
    return root;
}

class OsgWidget final : public QOpenGLWidget
{

public:
    explicit OsgWidget(QWidget* parent = nullptr)
        : QOpenGLWidget(parent)
    {
        setFocusPolicy(Qt::StrongFocus);

        // Viewer 基本配置
        _viewer.setThreadingModel(osgViewer::Viewer::SingleThreaded);
        _viewer.setKeyEventSetsDone(0); // 不让 ESC 结束
        _viewer.setSceneData(createTestGeometry());

        // 操作器
        _viewer.setCameraManipulator(new osgGA::TrackballManipulator);

        // 让 Viewer 有 Stats（虽然我们不显示 HUD，但要用它拿 FPS）
        _viewer.addEventHandler(new osgViewer::StatsHandler);

        // 本地 fallback FPS（不依赖 OSG Stats）
        _tickTimer.start();
    }

    osgViewer::Viewer* viewer() { return &_viewer; }

    void setFpsLabel(QLabel* label) { _fpsLabel = label; }

    void setShowFps(bool on)
    {
        _showFps = on;
        if (_fpsLabel) _fpsLabel->setVisible(on);
    }

    bool showFps() const { return _showFps; }

    // 提供给外部（Qt Timer）调用，刷新 Label 文本
    void updateFpsText()
    {
        if (!_showFps || !_fpsLabel) return;

        double fps = 0.0;

        // 优先从 OSG Stats 取（有时需要跑起来一段时间才稳定）
        osg::Stats* stats = _viewer.getViewerStats();
        if (stats)
        {
            // 取过去 0.5s 的平均帧率（更平滑）
            bool ok = stats->getAveragedAttribute("Frame rate", fps, 0.5);
            if (!ok || fps <= 0.0)
            {
                fps = fallbackFps();
            }
        }
        else
        {
            fps = fallbackFps();
        }

        _fpsLabel->setText(QString("FPS: %1").arg(fps, 0, 'f', 1));
    }

protected:
    void initializeGL() override
    {
        // 用嵌入式 GraphicsWindow，让 OSG 复用 Qt 的 GL Context
        _gw = new osgViewer::GraphicsWindowEmbedded(0, 0, width(), height());

        osg::Camera* cam = _viewer.getCamera();
        cam->setGraphicsContext(_gw.get());
        cam->setViewport(new osg::Viewport(0, 0, width(), height()));
        cam->setProjectionMatrixAsPerspective(45.0, double(width()) / double(height()), 0.1, 1000.0);

        // QOpenGLWidget 默认是 FBO，OSG 不需要去管 swap buffers
        cam->setDrawBuffer(GL_BACK);
        cam->setReadBuffer(GL_BACK);
    }

    void resizeGL(int w, int h) override
    {
        if (_gw.valid())
        {
            _gw->resized(0, 0, w, h);
            _gw->getEventQueue()->windowResize(0, 0, w, h);
        }

        osg::Camera* cam = _viewer.getCamera();
        if (cam)
        {
            cam->setViewport(0, 0, w, h);
            cam->setProjectionMatrixAsPerspective(45.0, double(w) / double(h), 0.1, 1000.0);
        }
    }

    void paintGL() override
    {
        _viewer.frame();
    }

    // --- Qt -> OSG 事件映射 ---
    osgGA::EventQueue* eventQueue() const
    {
        return _gw.valid() ? _gw->getEventQueue() : nullptr;
    }

    static int qtMouseButtonToOsg(Qt::MouseButton btn)
    {
        switch (btn)
        {
        case Qt::LeftButton:   return 1;
        case Qt::MiddleButton: return 2;
        case Qt::RightButton:  return 3;
        default:               return 0;
        }
    }

    void mousePressEvent(QMouseEvent* e) override
    {
        if (auto* q = eventQueue())
        {
            const int b = qtMouseButtonToOsg(e->button());
            q->mouseButtonPress(e->x(), e->y(), b);
        }
        update();
    }

    void mouseReleaseEvent(QMouseEvent* e) override
    {
        if (auto* q = eventQueue())
        {
            const int b = qtMouseButtonToOsg(e->button());
            q->mouseButtonRelease(e->x(), e->y(), b);
        }
        update();
    }

    void mouseMoveEvent(QMouseEvent* e) override
    {
        if (auto* q = eventQueue())
        {
            q->mouseMotion(e->x(), e->y());
        }
        update();
    }

    void wheelEvent(QWheelEvent* e) override
    {
        if (auto* q = eventQueue())
        {
            const auto delta = e->angleDelta().y();
            q->mouseScroll(delta > 0 ? osgGA::GUIEventAdapter::SCROLL_UP
                : osgGA::GUIEventAdapter::SCROLL_DOWN);
        }
        update();
    }

    void keyPressEvent(QKeyEvent* e) override
    {
        // F：切换 FPS 显示
        if (e->key() == Qt::Key_F)
        {
            setShowFps(!_showFps);
            e->accept();
            return;
        }

        if (auto* q = eventQueue())
        {
            // 这里只做基本转发（OSG 里常用 ASCII）
            const int key = e->text().isEmpty() ? e->key() : e->text().at(0).toLatin1();
            q->keyPress(key);
        }
        update();
    }

    void keyReleaseEvent(QKeyEvent* e) override
    {
        if (auto* q = eventQueue())
        {
            const int key = e->text().isEmpty() ? e->key() : e->text().at(0).toLatin1();
            q->keyRelease(key);
        }
        update();
    }

private:
    double fallbackFps()
    {
        // 纯 Qt 计时：统计 paintGL 调用频率（粗略但可靠）
        // 这里用“窗口 frame() 调用次数/时间”做一个平滑估算
        qint64 nowMs = _tickTimer.elapsed();
        _frameCount++;

        if (nowMs - _lastFpsMs >= 500) // 半秒更新一次
        {
            const qint64 dt = nowMs - _lastFpsMs;
            _lastFps = (dt > 0) ? (1000.0 * double(_frameCount) / double(dt)) : 0.0;
            _frameCount = 0;
            _lastFpsMs = nowMs;
        }
        return _lastFps;
    }

private:
    osgViewer::Viewer _viewer;
    osg::ref_ptr<osgViewer::GraphicsWindowEmbedded> _gw;

    QLabel* _fpsLabel = nullptr;
    bool _showFps = true;

    // fallback FPS
    QElapsedTimer _tickTimer;
    qint64 _lastFpsMs = 0;
    int _frameCount = 0;
    double _lastFps = 0.0;
};

class MainWindow final : public QMainWindow
{

public:
    MainWindow()
    {
        auto* central = new QWidget(this);
        auto* layout = new QVBoxLayout(central);
        layout->setContentsMargins(6, 6, 6, 6);
        layout->setSpacing(6);

        _osg = new OsgWidget(central);
        _fps = new QLabel("FPS: --", central);
        _fps->setMinimumHeight(22);

        layout->addWidget(_osg, 1);
        layout->addWidget(_fps, 0);

        setCentralWidget(central);
        resize(1000, 700);
        setWindowTitle("Qt + OSG Demo (Press F to toggle FPS)");

        _osg->setFpsLabel(_fps);
        _osg->setShowFps(true);

        // 用 Qt 定时器驱动刷新 FPS 文本（渲染仍由 QOpenGLWidget 的 update() + paintGL 驱动）
        auto* t = new QTimer(this);
        t->setInterval(200);
        connect(t, &QTimer::timeout, this, [this]() {
            _osg->updateFpsText();
            _osg->update(); // 让画面持续刷新（你也可以改成按需刷新）
            });
        t->start();
    }

private:
    OsgWidget* _osg = nullptr;
    QLabel* _fps = nullptr;
};

int main(int argc, char** argv)
{
    QApplication app(argc, argv);
    MainWindow w;
    w.show();
    return app.exec();
}

