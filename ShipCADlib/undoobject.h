/*##############################################################################################
 *    ShipCAD																				   *
 *    Copyright 2015, by Greg Green <ggreen@bit-builder.com>								   *
 *    Original Copyright header below														   *
 *																							   *
 *    This code is distributed as part of the FREE!ship project. FREE!ship is an               *
 *    open source surface-modelling program based on subdivision surfaces and intended for     *
 *    designing ships.                                                                         *
 *                                                                                             *
 *    Copyright © 2005, by Martijn van Engeland                                                *
 *    e-mail                  : Info@FREEship.org                                              *
 *    FREE!ship project page  : https://sourceforge.net/projects/freeship                      *
 *    FREE!ship homepage      : www.FREEship.org                                               *
 *                                                                                             *
 *    This program is free software; you can redistribute it and/or modify it under            *
 *    the terms of the GNU General Public License as published by the                          *
 *    Free Software Foundation; either version 2 of the License, or (at your option)           *
 *    any later version.                                                                       *
 *                                                                                             *
 *    This program is distributed in the hope that it will be useful, but WITHOUT ANY          *
 *    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A          *
 *    PARTICULAR PURPOSE. See the GNU General Public License for more details.                 *
 *                                                                                             *
 *    You should have received a copy of the GNU General Public License along with             *
 *    this program; if not, write to the Free Software Foundation, Inc.,                       *
 *    59 Temple Place, Suite 330, Boston, MA 02111-1307 USA                                    *
 *                                                                                             *
 *#############################################################################################*/

#ifndef UNDOOBJECT_H_
#define UNDOOBJECT_H_

#include <QtCore>
#include <QtGui>
#include "filebuffer.h"
#include "shipcadlib.h"

namespace ShipCAD {

class ShipCADModel;

//////////////////////////////////////////////////////////////////////////////////////

class UndoObject : public QObject
{
    Q_OBJECT
public:

    explicit UndoObject(ShipCADModel* owner, const QString& filename,
                        edit_mode_t mode, bool file_changed, bool filename_set,
                        bool is_temp_redo_ob);
    ~UndoObject() {}

    size_t getMemory();
	bool isTempRedoObject() const
		{return _is_temp_redo_obj;}
	void setTempRedoObject(bool set)
		{_is_temp_redo_obj = set;}
	QString getTime() const
		{return _time.toString("hh:mm:ss.zzz");}
    QString getUndoText() const
		{return _undo_text;}
    void setUndoText(const QString& txt)
        {_undo_text = txt;}
	FileBuffer& getUndoData()
        {return _undo_data;}
	void accept();
	void restore();
	
private:

	ShipCADModel* _owner;
	QString _undo_text;
	FileBuffer _undo_data;
	bool _file_changed;
	bool _filename_set;
	QString _filename;
    edit_mode_t _edit_mode;
	QTime _time;
	bool _is_temp_redo_obj;
};

//////////////////////////////////////////////////////////////////////////////////////

};				/* end namespace */

#endif

