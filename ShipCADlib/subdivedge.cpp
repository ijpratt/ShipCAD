#include <iostream>
#include <cmath>
#include <stdexcept>
#include <typeinfo>

#include "subdivedge.h"
#include "subdivsurface.h"
#include "subdivpoint.h"
#include "subdivface.h"
#include "subdivcontrolcurve.h"
#include "subdivlayer.h"
#include "viewport.h"
#include "filebuffer.h"

using namespace std;
using namespace ShipCADGeometry;

//////////////////////////////////////////////////////////////////////////////////////

SubdivisionEdge::SubdivisionEdge(SubdivisionSurface* owner)
    : SubdivisionBase(owner)
{
    clear();
}

SubdivisionEdge::~SubdivisionEdge()
{
    // does nothing
}

void SubdivisionEdge::clear()
{
    _points[0] = _points[1] = 0;
    _curve = 0;
    _faces.clear();
    _crease = false;
    _control_edge = false;
}

size_t SubdivisionEdge::getIndex()
{
    try {
        return _owner->indexOfEdge(this);
    }
    catch(range_error&) {
        return _owner->indexOfControlEdge(static_cast<SubdivisionControlEdge*>(this));
    }
}

bool SubdivisionEdge::isBoundaryEdge()
{
    bool result = false;
    if (_faces.size() == 1) {
        result = (fabs(_points[0]->getCoordinate().y()) > 1E-4f
                || fabs(_points[1]->getCoordinate().y()) > 1E-4f);
    }
    return result;
}

SubdivisionFace* SubdivisionEdge::getFace(size_t index)
{
    if (index < _faces.size())
        return _faces[index];
    throw range_error("SubdivisionEdge::getFace");
}

bool SubdivisionEdge::hasFace(SubdivisionFace* face)
{
    return (find(_faces.begin(), _faces.end(), face) != _faces.end());
}

void SubdivisionEdge::setCrease(bool val)
{
    if (_faces.size() == 1)
        val = true;			// boundary edges must always be crease edges
    if (val == _crease)
        return;
    _crease = val;
    int n = 0;
    SubdivisionPoint* startPoint = _points[0];
    SubdivisionPoint* endPoint = _points[1];
    for (size_t i = 0; i<startPoint->numberOfEdges(); ++i) {
        SubdivisionEdge* edge = startPoint->getEdge(i);
        if (edge->isCrease())
            n++;
    }
    if (startPoint->getVertexType() == SubdivisionPoint::svCorner) {
        if (startPoint->numberOfFaces() > 1 && n == 2)
            startPoint->setVertexType(SubdivisionPoint::svCrease);
    }
    else {
        if (n == 0)
            startPoint->setVertexType(SubdivisionPoint::svRegular);
        else if (n == 1)
            startPoint->setVertexType(SubdivisionPoint::svDart);
        else if (n == 2)
            startPoint->setVertexType(SubdivisionPoint::svCrease);
        else if (n > 2)
            startPoint->setVertexType(SubdivisionPoint::svCorner);
    }
    n = 0;
    for (size_t i=0; i<endPoint->numberOfEdges(); ++i) {
        SubdivisionEdge* edge = endPoint->getEdge(i);
        if (edge->isCrease())
            n++;
    }
    if (endPoint->getVertexType() == SubdivisionPoint::svCorner) {
        if (endPoint->numberOfFaces() > 1 && n == 2)
            endPoint->setVertexType(SubdivisionPoint::svCrease);
    }
    else {
        if (n == 0)
            endPoint->setVertexType(SubdivisionPoint::svRegular);
        else if (n == 1)
            endPoint->setVertexType(SubdivisionPoint::svDart);
        else if (n == 2)
            endPoint->setVertexType(SubdivisionPoint::svCrease);
        else if (n > 2)
            endPoint->setVertexType(SubdivisionPoint::svCorner);
    }
    _owner->setBuild(false);
}

SubdivisionEdge* SubdivisionEdge::getPreviousEdge()
{
    SubdivisionPoint* p = _points[0];
    SubdivisionEdge* result = 0;
    if (p->isRegularPoint() && p->getVertexType() != SubdivisionPoint::svCorner) {
        // find previous edge
        for (size_t i=0; i<p->numberOfEdges(); ++i) {
            if (p->getEdge(i) == this)
                continue;
            SubdivisionEdge* edge = p->getEdge(i);
            if (edge->isCrease() == isCrease()) {
                bool shares_face = false;
                for (size_t j=0; j<_faces.size(); ++j) {
                    if (edge->hasFace(_faces[j])) {
                        shares_face = true;
                        break;
                    }
                }
                if (!shares_face) {
                    if (edge->startPoint() == startPoint())
                        edge->swapData();
                    result = edge;
                    break;
                }
            }
        }
    }
    return result;
}

SubdivisionEdge* SubdivisionEdge::getNextEdge()
{
    SubdivisionPoint* p = _points[1];
    SubdivisionEdge* result = 0;
    if (p->isRegularPoint() && p->getVertexType() != SubdivisionPoint::svCorner) {
        // find next edge
        for (size_t i=0; i<p->numberOfEdges(); ++i) {
            if (p->getEdge(i) == this)
                continue;
            SubdivisionEdge* edge = p->getEdge(i);
            if (edge->isCrease() == isCrease()) {
                bool shares_face = false;
                for (size_t j=0; j<_faces.size(); ++j) {
                    if (edge->hasFace(_faces[j])) {
                        shares_face = true;
                        break;
                    }
                }
                if (!shares_face) {
                    if (edge->startPoint() == startPoint())
                        edge->swapData();
                    result = edge;
                    break;
                }
            }
        }
    }
    return result;
}

void SubdivisionEdge::addFace(SubdivisionFace* face)
{
    if (!hasFace(face))
        _faces.push_back(face);
}

SubdivisionPoint* SubdivisionEdge::calculateEdgePoint()
{
    QVector3D point = 0.5 * startPoint()->getCoordinate() * endPoint()->getCoordinate();
    SubdivisionPoint* result = new SubdivisionPoint(_owner);
    if (_crease)
        result->setVertexType(SubdivisionPoint::svCrease);
    if (_curve)
        _curve->insertEdgePoint(startPoint(), endPoint(), result);
    result->setCoordinate(point);
    return result;
}

void SubdivisionEdge::swapData()
{
    swap(_points[0], _points[1]);
}

void SubdivisionEdge::deleteFace(SubdivisionFace* face)
{
    if (hasFace(face)) {
        vector<SubdivisionFace*>::iterator del = find(_faces.begin(), _faces.end(), face);
        _faces.erase(del);
        if (_faces.size() == 1)
            _crease = true;
        else if (_faces.size() == 0)
            _crease = false;
    }
}

void SubdivisionEdge::draw(Viewport& /*vp*/)
{
}

void SubdivisionEdge::dump(ostream& os, const char* prefix) const
{
    os << prefix << "SubdivisionEdge ["
       << hex << this << "]\n";
    priv_dump(os, prefix);
}

void SubdivisionEdge::priv_dump(ostream& os, const char* prefix) const
{
    SubdivisionBase::priv_dump(os, prefix);
}

ostream& operator << (ostream& os, const ShipCADGeometry::SubdivisionEdge& edge)
{
    edge.dump(os);
    return os;
}

SubdivisionControlEdge::SubdivisionControlEdge(SubdivisionSurface* owner)
    : SubdivisionEdge(owner)
{
    clear();
}

SubdivisionControlEdge::~SubdivisionControlEdge()
{
    // delete from selection
    setSelected(false);
    if (getCurve() != 0)
        getCurve()->deleteEdge(this);
    _owner->deleteControlEdge(this);
    for (size_t i=_faces.size(); i>0; --i)
        delete _faces[i-1];
    // remove endpoint from startpoint neighbours
    endPoint()->deleteEdge(this);
    if (endPoint()->numberOfEdges() == 0)
        delete endPoint();
    // remove startpoint from endpoint neighbours
    startPoint()->deleteEdge(this);
    if (startPoint()->numberOfEdges() == 0)
        delete startPoint();
}

void SubdivisionControlEdge::collapse()
{
    const type_info& this_type = typeid(this);
    if (_faces.size() == 2 \
            && typeid(_faces[0]) == this_type
            && typeid(_faces[1]) == this_type) {

        SubdivisionControlPoint* s,*e;
        SubdivisionControlFace* face1,*face2;
        SubdivisionPoint* p1, *p2;

        if (startPoint()->numberOfEdges() > 2 && endPoint()->numberOfEdges() > 2) {
            if (getCurve() != 0)
                getCurve()->deleteEdge(this);
            if (isSelected())
                setSelected(false);
            s = dynamic_cast<SubdivisionControlPoint*>(startPoint());
            e = dynamic_cast<SubdivisionControlPoint*>(endPoint());
            _owner->setBuild(false);
            face1 = dynamic_cast<SubdivisionControlFace*>(_faces[0]);
            face2 = dynamic_cast<SubdivisionControlFace*>(_faces[1]);
            // check faces for consistent ordering of the points (same normal direction)
            // because inconsistent ordering can lead to access violations
            p1 = face1->getPoint(face1->numberOfPoints()-1);
            for (size_t i=0; i<face1->numberOfPoints(); ++i) {
                p2 = face1->getPoint(i);
                if ((p1 == startPoint() && p2 == endPoint())
                        || ((p2 == startPoint() && p1 == endPoint()))) {
                    size_t ind1 = face2->indexOfPoint(p2);
                    size_t ind2 = (ind1 + 1) % face2->numberOfPoints(); // select the next index
                    if (face2->getPoint(ind2) != p1) {
                        face2->flipNormal();
                    }
                    break;
                }
                else
                    p1 = p2;
            }
        }

        SubdivisionLayer* layer = face1->getLayer();
        // remove the control faces from the layers they belong to
        face1->getLayer()->deleteControlFace(face1);
        face2->getLayer()->deleteControlFace(face2);
        size_t ind1 = face1->indexOfPoint(startPoint());
        size_t ind2 = face1->indexOfPoint(endPoint());
        if (ind2 < ind1 && fabs(static_cast<float>(ind2 - ind1)) == 1.0f)
            swap(ind1, ind2);
        size_t ind3 = face2->indexOfPoint(startPoint());
        size_t ind4 = face2->indexOfPoint(endPoint());
        if (ind4 < ind3 && fabs(static_cast<float>(ind4 - ind3)) == 1.0f)
            swap(ind3, ind4);
        if (ind1 == 0 && ind2 == face1->numberOfPoints() - 1
                && ind3 == 0 && ind4 == face2->numberOfPoints() - 1) {
            swap(ind1, ind2);
            swap(ind3, ind4);
        }
        if (ind1 == 0 && ind2 == face1->numberOfPoints() - 1)
            swap(ind1, ind2);
        if (ind3 == 0 && ind4 == face2->numberOfPoints() - 1)
            swap(ind3, ind4);
        // remove all references to face1
        for (size_t i=0; i<face1->numberOfPoints(); ++i)
            face1->getPoint(i)->deleteFace(face1);
        // remove all references to face2
        for (size_t i=0; i<face2->numberOfPoints(); ++i)
            face2->getPoint(i)->deleteFace(face2);
        // add the new face
        SubdivisionControlFace* newface = new SubdivisionControlFace(_owner);
        newface->setLayer(layer);
        _owner->addControlFace(newface);
        for (size_t i=0; i<=ind1; ++i) {
            newface->addPoint(face1->getPoint(i));
        }
        for (size_t i=ind4; i<face2->numberOfPoints(); ++i)
            newface->addPoint(face2->getPoint(i));
        for (size_t i=0; i<=ind3; ++i)
            newface->addPoint(face2->getPoint(i));
        for (size_t i=ind2; i<face1->numberOfPoints(); ++i)
            newface->addPoint(face1->getPoint(i));
        // check all appropriate points are added
        if (newface->numberOfPoints() != face1->numberOfPoints() + face2->numberOfPoints() - 2)
            throw runtime_error("wrong number of points in SubdivisionControlEdge::collapse");
        p1 = newface->getPoint(newface->numberOfPoints() - 1);
        for (size_t i=0; i<newface->numberOfPoints(); ++i) {
            p2 = newface->getPoint(i);
            SubdivisionEdge* edge = _owner->edgeExists(p1, p2);
            if (edge != 0) {
                if (edge->hasFace(face1))
                    edge->deleteFace(face1);
                if (edge->hasFace(face2))
                    edge->deleteFace(face2);
                edge->addFace(newface);
                if (edge->numberOfFaces() < 2)
                    edge->setCrease(true);
            }
            p1 = p2;
        }
        // connect the new face to a layer
        layer->addControlFace(newface);
        if (isCrease())
            setCrease(false);
        startPoint()->deleteEdge(this);
        endPoint()->deleteEdge(this);
        if (_owner->hasControlEdge(this))
            _owner->deleteControlEdge(this);
        if (_owner->hasControlFace(face1))
            _owner->deleteControlFace(face1);
        if (_owner->hasControlFace(face2))
            _owner->deleteControlFace(face2);
        delete face1;
        delete face2;

        // check if startpoint and endpoint can be collapsed as well
        if (s->numberOfFaces() > 1 && s->numberOfEdges() == 2)
            s->collapse();
        if (e->numberOfFaces() > 1 && e->numberOfEdges() == 2)
            e->collapse();
        _owner->setBuild(false);
        // BUGBUG: pascal deletes edge here, but we can't do that...
    }   // end edge number == 2
}

QColor SubdivisionControlEdge::getColor()
{
    QColor result;
    if (_selected)
        result = _owner->getSelectedColor();
    else if (_faces.size() > 2)
        result = Qt::green;
    else if (_crease)
        result = _owner->getCreaseEdgeColor();
    else
        result = _owner->getEdgeColor();
    return result;
}

size_t SubdivisionControlEdge::getIndex()
{
    return _owner->indexOfControlEdge(this);
}

bool SubdivisionControlEdge::isBoundaryEdge()
{
    bool result = false;
    int n = 0;
    for (size_t i=0; i<_faces.size(); ++i) {
        SubdivisionControlFace* face = dynamic_cast<SubdivisionControlFace*>(_faces[i]);
        if (face && face->getLayer()->useInHydrostatics())
            n++;
    }
    if (n == 1)
        result = (fabs(startPoint()->getCoordinate().y()) > 1E-4f
                  || fabs(endPoint()->getCoordinate().y()) > 1E-4f);
    return result;
}

void SubdivisionControlEdge::setSelected(bool val)
{
    if (val)
        _owner->setSelectedControlEdge(this);
    else
        _owner->removeSelectedControlEdge(this);
}

bool SubdivisionControlEdge::isSelected()
{
    return _owner->hasSelectedControlEdge(this);
}

bool SubdivisionControlEdge::isVisible()
{
    // meant for control edges only
    // a control edge is visible if at least one of it's
    //  neighbouring control faces belongs to a visible layer
    bool result = false;

    if (_owner->showControlNet()) {
        for (size_t i=0; i<_faces.size(); ++i) {
            SubdivisionControlFace* cface = dynamic_cast<SubdivisionControlFace*>(_faces[i]);
            if (cface != 0 && cface->getLayer() != 0) {
                if (cface->getLayer()->isVisible()) {
                    result = true;
                    break;
                }
            }
        }
    }

    // finally check if the edge is selected
    // selected edges must be visible at all times
    if (!result)
        result = isSelected();
    if (!result && getCurve() != 0)
        result = getCurve()->isSelected();
    return result;
}

SubdivisionControlPoint* SubdivisionControlEdge::insertControlPoint(const QVector3D& p)
{
    SubdivisionControlPoint* result = new SubdivisionControlPoint(_owner);
    SubdivisionControlPoint* sp = dynamic_cast<SubdivisionControlPoint*>(startPoint());
    SubdivisionControlPoint* ep = dynamic_cast<SubdivisionControlPoint*>(endPoint());
    if (sp == 0 || ep == 0)
        throw runtime_error("start and/or end point are not control points");
    result->setCoordinate(p);
    if (getCurve() != 0) {
        // insert the new point in the controlcurve
        getCurve()->insertControlPoint(sp, ep, result);
    }
    _owner->addControlPoint(result);
    for (size_t i=0; i<_faces.size(); ++i) {
        SubdivisionFace* face = _faces[i];
        if (face->hasPoint(sp) && face->hasPoint(ep)) {
            size_t i1 = face->indexOfPoint(sp);
            size_t i2 = face->indexOfPoint(ep);
            if (i2 == i1+1)
                face->insertPoint(i2, result);
            else if (i1 == i2+1)
                face->insertPoint(i1, result);
            else if (i1 == 0 && i2 == face->numberOfPoints() - 1)
                face->insertPoint(0, result);
            else if (i2 == 0 && i1 == face->numberOfPoints() - 1)
                face->insertPoint(0, result);
            result->addFace(face);
        }
    }
    ep->deleteEdge(this);
    SubdivisionControlEdge* edge = _owner->addControlEdge(result, ep);
    edge->setCrease(isCrease());
    edge->setCurve(getCurve());
    if (getCurve())
        result->setVertexType(SubdivisionPoint::svCrease);
    for (size_t i=0; i<_faces.size(); ++i)
        edge->addFace(_faces[i]);
    _points[1] = result;
    result->addEdge(this);
    return result;
}

void SubdivisionControlEdge::load_binary(FileBuffer& source)
{
    size_t index;
    // read startpoint
    source.load(index);
    _points[0] = _owner->getControlPoint(index);
    _points[0]->addEdge(this);
    // read endpoint
    source.load(index);
    _points[1] = _owner->getControlPoint(index);
    _points[1]->addEdge(this);
    bool val;
    source.load(val);
    setCrease(val);
    source.load(val);
    setSelected(val);
}

void SubdivisionControlEdge::loadFromStream(size_t &lineno, std::vector<QString> &strings)
{
    // BUGBUG: not implemented
}

void SubdivisionControlEdge::save_binary(FileBuffer& destination)
{
    destination.add(_owner->indexOfPoint(_points[0]));
    destination.add(_owner->indexOfPoint(_points[1]));
    destination.add(isCrease());
    destination.add(isSelected());
}

void SubdivisionControlEdge::priv_trace(SubdivisionControlPoint* p)
{
    SubdivisionControlEdge* edge;
    if (p->isRegularPoint() && p->getVertexType() != SubdivisionPoint::svCorner) {
        // find next edge
        for (size_t i=0; i<p->numberOfEdges(); ++i) {
            if (p->getEdge(i) != this) {
                edge = dynamic_cast<SubdivisionControlEdge*>(p->getEdge(i));
                if (edge->isSelected() != isSelected() && edge->isCrease() == isCrease()) {
                    bool shares_face = false;
                    for (size_t j=0; j<numberOfFaces(); ++j) {
                        if (edge->hasFace(_faces[j])) {
                            shares_face = true;
                            break;
                        }
                    }
                    if (!shares_face) {
                        if (edge->startPoint() == startPoint())
                            edge->swapData();
                        edge->setSelected(isSelected());
                        edge->trace();
                        break;
                    }
                }
            }
        }
    }
}

void SubdivisionControlEdge::trace()
{
    SubdivisionControlPoint* p;

    p = dynamic_cast<SubdivisionControlPoint*>(startPoint());
    priv_trace(p);
    p = dynamic_cast<SubdivisionControlPoint*>(endPoint());
    priv_trace(p);
}

void SubdivisionControlEdge::draw(Viewport& /*vp*/)
{

}

void SubdivisionControlEdge::draw(bool draw_mirror, Viewport& /*vp*/)
{

}

void SubdivisionControlEdge::dump(ostream& os, const char* prefix) const
{
    os << prefix << "SubdivisionControlEdge ["
       << hex << this << "]\n";
    priv_dump(os, prefix);
}

void SubdivisionControlEdge::priv_dump(ostream& os, const char* prefix) const
{
    SubdivisionEdge::priv_dump(os, prefix);
}

ostream& operator << (ostream& os, const ShipCADGeometry::SubdivisionControlEdge& edge)
{
    edge.dump(os);
    return os;
}
